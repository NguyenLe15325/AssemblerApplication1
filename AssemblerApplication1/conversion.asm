convert_display:
    ldi r20, '0'-1
d1k:
    inc r20
    subi angle_l, low(1000)
    sbci angle_h, high(1000)
    brcc d1k
    subi angle_l, low(-1000)
    sbci angle_h, high(-1000)
    rcall print_r
    
    ldi r20, '0'-1
d1h:
    inc r20
    subi angle_l, low(100)
    sbci angle_h, high(100)
    brcc d1h
    subi angle_l, low(-100)
    sbci angle_h, high(-100)
    rcall print_r
    
    ldi r20, '0'-1
d1t:
    inc r20
    subi angle_l, 10
    sbci angle_h, 0
    brcc d1t
    subi angle_l, -10
    
    mov temp, r20
    rcall lcd_data
    mov temp, angle_l
    subi temp, -'0'
    rcall lcd_data
    ret

print_r:
    mov temp, r20
    rcall lcd_data
    ret