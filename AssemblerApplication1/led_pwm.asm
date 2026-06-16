.def pwm_counter  = r21
.def brightness   = r22

led_pwm_init:
    sbi DDRB, 5              ; PB5 Output (Built-in LED)
    ldi temp, (1<<CS00)      ; Timer0 prescaler 1
    out TCCR0B, temp
    ldi temp, (1<<TOIE0)
    sts TIMSK0, temp
    ret

led_pwm_update:
    mov temp, angle_l
    swap temp
    andi temp, 0x0F
    
    mov brightness, angle_h
    swap brightness
    or brightness, temp
    ret

timer0_ovf_isr:
    push temp
    in temp, SREG
    push temp
    
    inc pwm_counter
    cp pwm_counter, brightness
    brlo led_high
    
    cbi PORTB, 5
    rjmp end_isr
    
led_high:
    sbi PORTB, 5
    
end_isr:
    pop temp
    out SREG, temp
    pop temp
    reti
