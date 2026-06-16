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
    
    ; Configure Timer0 clock source: CS02=0, CS01=0, CS00=1 = No Prescaler (fastest)
    ; Register TCCR0B starts at 0, so only setting CS00=1 is needed.
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
    ; Goal: Map the 12-bit angle (0-4095) to 8-bit brightness (0-255) = angle / 16
    ;
    ; The 12-bit angle occupies two registers like this (bit positions):
    ;
    ;   angle_h: [ 0   0   0   0 | 11  10   9   8 ]
    ;   angle_l: [ 7   6   5   4 |  3   2   1   0 ]
    ;
    ; Dividing by 16 = shift right 4. The 8-bit result keeps bits [11:4]:
    ;
    ;   brightness: [ 11  10   9   8 |  7   6   5   4 ]
    ;                 ^-- angle_h --^   ^-- angle_l --^
    ;                 (shift left 4)    (shift right 4)
    ;
    ; Bits [3:0] of the angle are simply discarded (not needed).
    ; --------------------------------------------------------------------------

    ; --- Step 1: Get bits [7:4] from angle_l into positions [3:0] ---
    mov temp, angle_l
    lsr temp                 ; shift right 1
    lsr temp                 ; shift right 2
    lsr temp                 ; shift right 3
    lsr temp                 ; shift right 4 → bits [7:4] now sit in [3:0]
    ; 'temp' now holds the LOWER half of brightness

    ; --- Step 2: Get bits [11:8] from angle_h into positions [7:4] ---
    mov brightness, angle_h
    lsl brightness           ; shift left 1
    lsl brightness           ; shift left 2
    lsl brightness           ; shift left 3
    lsl brightness           ; shift left 4 → bits [3:0] now sit in [7:4]
    ; 'brightness' now holds the UPPER half of brightness

    ; --- Step 3: Combine both halves ---
    or brightness, temp      ; merge upper [7:4] and lower [3:0] into one byte
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
