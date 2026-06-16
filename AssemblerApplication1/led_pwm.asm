.def pwm_counter  = r21
.def brightness   = r22

led_pwm_init:
    sbi DDRB, 5
    ; No Prescaler
    ldi temp, (1<<CS00)
    out TCCR0B, temp	
    ; Overflow interupt enable
    ldi temp, (1<<TOIE0)
    sts TIMSK0, temp	
    ret

led_pwm_update:
    mov temp, angle_l
    lsr temp
    lsr temp
    lsr temp
    lsr temp

    mov brightness, angle_h
    lsl brightness
    lsl brightness
    lsl brightness
    lsl brightness

    or brightness, temp
    ret

timer0_ovf_isr:
    push temp
    in temp, SREG
    push temp
    
    inc pwm_counter
    
    cp pwm_counter, brightness
    brlo led_high
    
    cbi PORTB, 5	; led low
    rjmp end_isr
    
led_high:
    sbi PORTB, 5
    
end_isr:
    pop temp
    out SREG, temp
    pop temp
    reti