convert_display:
    ldi r20, '0'

count_1000s:
    subi angle_l, low(1000)
    sbci angle_h, high(1000)
    brcs restore_1000s
    
    inc r20
    rjmp count_1000s

restore_1000s:
    ldi temp, low(1000)
    add angle_l, temp
    ldi temp, high(1000)
    adc angle_h, temp
    
    rcall print_digit
    
    ldi r20, '0'

count_100s:
    subi angle_l, low(100)
    sbci angle_h, high(100)
    brcs restore_100s
    
    inc r20
    rjmp count_100s

restore_100s:
    ldi temp, low(100)
    add angle_l, temp
    ldi temp, high(100)
    adc angle_h, temp
    
    rcall print_digit
    
    ldi r20, '0'

count_10s:
    subi angle_l, 10
    sbci angle_h, 0
    brcs restore_10s
    
    inc r20
    rjmp count_10s

restore_10s:
    ldi temp, 10
    add angle_l, temp
    ldi temp, 0
    adc angle_h, temp
    
    rcall print_digit
    
    mov temp, angle_l
    ldi r20, '0'
    add temp, r20
    rcall lcd_data
    
    ret

print_digit:
    mov temp, r20
    rcall lcd_data
    ret