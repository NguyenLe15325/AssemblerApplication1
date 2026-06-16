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
    ; This routine scales the 12-bit angle (0-4095) down to 8-bit brightness (0-255).
    ; Mathematically, this is division by 16. In binary, division by 16 is 
    ; identical to shifting all the bits to the right 4 times.
    ; --------------------------------------------------------------------------
    mov brightness, angle_h  ; Start with the upper bits
    mov temp, angle_l        ; And the lower bits
    
    ; Shift Right 1st time
    lsr brightness           ; Logical Shift Right (moves bit 0 into Carry flag)
    ror temp                 ; Rotate Right through Carry (moves Carry into bit 7)
    
    ; Shift Right 2nd time
    lsr brightness
    ror temp
    
    ; Shift Right 3rd time
    lsr brightness
    ror temp
    
    ; Shift Right 4th time
    lsr brightness
    ror temp
    
    mov brightness, temp     ; The fully shifted 8-bit result is our new brightness!
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
