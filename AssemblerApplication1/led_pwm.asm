; ==============================================================================
; Software PWM LED Driver
; ------------------------------------------------------------------------------
; Since the built-in LED (Pin 13 / PB5) does not have hardware PWM capabilities,
; we use Timer0 to generate a fast interrupt. Inside this interrupt, we manually
; turn the LED on or off to create a custom "Software PWM" signal.
; ==============================================================================

.def pwm_counter  = r21    ; Keeps track of the current PWM step (0 to 255)
.def brightness   = r22    ; The target brightness we want to achieve (0 to 255)

led_pwm_init:
    ; 1. Set the Data Direction Register for Port B, Bit 5 to OUTPUT.
    sbi DDRB, 5              ; PB5 is connected to the Arduino's built-in LED.
    
    ; 2. Configure Timer0 to run at full CPU speed (No Prescaler).
    ; At 16 MHz, the timer ticks 16,000,000 times a second.
    ldi temp, (1<<CS00)      
    out TCCR0B, temp
    
    ; 3. Enable the Timer0 Overflow Interrupt.
    ; This will force the CPU to jump to 'timer0_ovf_isr' every 256 ticks.
    ; Interrupt rate = 16MHz / 256 = 62.5 kHz.
    ldi temp, (1<<TOIE0)
    sts TIMSK0, temp
    ret

led_pwm_update:
    ; --------------------------------------------------------------------------
    ; Goal: Map the 12-bit angle (0-4095) down to 8-bit brightness (0-255).
    ; This is the same as dividing by 16 (shifting the binary number right 4 places).
    ;
    ; The 12-bit angle is stored across two registers:
    ;   angle_h = bits 11-8  (upper 4 bits)
    ;   angle_l = bits  7-0  (lower 8 bits)
    ;
    ; After dividing by 16, we want:
    ;   brightness bit 7-4 = angle bits 11-8  (from angle_h)
    ;   brightness bit 3-0 = angle bits  7-4  (top 4 bits of angle_l)
    ; --------------------------------------------------------------------------

    ; --- Step 1: Extract the upper 4 bits of angle_l (bits 7-4) ---
    ; Shift angle_l right 4 times so bits 7-4 drop into positions 3-0
    mov temp, angle_l
    lsr temp                 ; bit 7->6, 6->5, 5->4, 4->3
    lsr temp                 ; bit 7->6, 6->5, 5->4, 4->3
    lsr temp                 ; bit 7->6, 6->5, 5->4, 4->3
    lsr temp                 ; bits 7-4 are now sitting in positions 3-0
    ; 'temp' now holds the LOWER half of brightness

    ; --- Step 2: Put angle_h into the upper 4 bits of brightness ---
    ; angle_h already has our bits in positions 3-0, we need to move them to 7-4
    mov brightness, angle_h
    lsl brightness           ; shift left 4 times to move bits 3-0 up to 7-4
    lsl brightness
    lsl brightness
    lsl brightness
    ; 'brightness' now holds the UPPER half of brightness

    ; --- Step 3: Combine both halves ---
    or brightness, temp      ; merge the upper 4 bits and lower 4 bits
    ret

timer0_ovf_isr:
    ; --------------------------------------------------------------------------
    ; Interrupt Service Routine for Timer0 Overflow
    ; This routine pauses the main code and runs 62,500 times per second!
    ; --------------------------------------------------------------------------
    
    ; 1. Protect the CPU state. We must save the Status Register (SREG) and 'temp'
    ; because the main program might be using them when the interrupt fired.
    push temp
    in temp, SREG
    push temp
    
    ; 2. Advance our PWM counter. It goes 0, 1, 2... 255, and then wraps back to 0.
    inc pwm_counter
    
    ; 3. Compare the counter against our target brightness.
    cp pwm_counter, brightness
    brlo led_high            ; If counter < brightness, jump to turn LED ON
    
    ; 4. Otherwise, counter >= brightness, so turn LED OFF
    cbi PORTB, 5             ; Clear Bit in I/O Register (Sets PB5 LOW)
    rjmp end_isr             ; Skip the LED ON code
    
led_high:
    sbi PORTB, 5             ; Set Bit in I/O Register (Sets PB5 HIGH)
    
end_isr:
    ; 5. Restore the CPU state exactly as we found it.
    pop temp
    out SREG, temp
    pop temp
    reti                     ; Return from Interrupt
