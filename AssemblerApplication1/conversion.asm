; ==============================================================================
; Binary to Decimal Conversion Utilities
; ------------------------------------------------------------------------------
; This module converts a 16-bit binary number (like our 12-bit angle 0-4095)
; into printable ASCII characters on the LCD. Since the ATmega328P doesn't have
; a hardware division instruction, we use the "Repeated Subtraction" method.
; ==============================================================================

convert_display:
    ; We subtract 1000 repeatedly until we underflow. The number of successful 
    ; subtractions becomes the "thousands" digit. Then we do the same for 100s and 10s.
    
    ldi r20, '0'-1           ; Start the digit counter at the ASCII character right before '0'
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