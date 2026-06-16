
; ==============================================================================
; Binary to Decimal Conversion
; ------------------------------------------------------------------------------
; This module converts our 12-bit binary angle (a number between 0 and 4095)
; into printable ASCII characters to display on the LCD.
; 
; The ATmega328P processor DOES NOT have a division instruction. 
; To extract the thousands, hundreds, and tens digits, we use a technique called
; "Repeated Subtraction". We literally just subtract 1000 over and over again
; until the number drops below 0, counting how many times we did it.
; ==============================================================================

convert_display:
    
    ; --------------------------------------------------------------------------
    ; 1. EXTRACT THOUSANDS DIGIT
    ; --------------------------------------------------------------------------
    ; Strategy: Subtract 1000 repeatedly. Count only successful subtractions.
    ; We start at '0' and increment AFTER a successful subtraction.
    ldi r20, '0'

count_1000s:
    subi angle_l, low(1000)   ; Subtract 1000 from the 16-bit angle
    sbci angle_h, high(1000)
    brcs done_1000s           ; Carry SET = went below 0 → stop, we subtracted too much
    inc r20                   ; Subtraction was successful → count it!
    rjmp count_1000s

done_1000s:
    ; We went one subtraction too far. Add 1000 back to repair the number.
    ldi temp, low(1000)
    add angle_l, temp
    ldi temp, high(1000)
    adc angle_h, temp
    
    rcall print_digit         ; Print the thousands digit to the LCD
    
    
    ; --------------------------------------------------------------------------
    ; 2. EXTRACT HUNDREDS DIGIT
    ; --------------------------------------------------------------------------
    ldi r20, '0'

count_100s:
    subi angle_l, low(100)
    sbci angle_h, high(100)
    brcs done_100s            ; Carry SET = went below 0 → stop
    inc r20                   ; Subtraction was successful → count it!
    rjmp count_100s

done_100s:
    ldi temp, low(100)
    add angle_l, temp
    ldi temp, high(100)
    adc angle_h, temp
    
    rcall print_digit         ; Print the hundreds digit to the LCD
    
    
    ; --------------------------------------------------------------------------
    ; 3. EXTRACT TENS DIGIT
    ; --------------------------------------------------------------------------
    ldi r20, '0'

count_10s:
    subi angle_l, 10
    sbci angle_h, 0
    brcs done_10s             ; Carry SET = went below 0 → stop
    inc r20                   ; Subtraction was successful → count it!
    rjmp count_10s

done_10s:
    ldi temp, 10
    add angle_l, temp
    ldi temp, 0
    adc angle_h, temp
    
    rcall print_digit         ; Print the tens digit to the LCD
    
    
    ; --------------------------------------------------------------------------
    ; 4. PRINT ONES DIGIT
    ; --------------------------------------------------------------------------
    ; After extracting 1000s, 100s, and 10s, whatever remains in angle_l 
    ; IS the ones digit! (It will be a number between 0 and 9)
    
    mov temp, angle_l
    ldi r20, '0'
    add temp, r20             ; Add ASCII '0' to convert number to printable character
    rcall lcd_data
    
    ret


; ------------------------------------------------------------------------------
; Helper Subroutine: Print Digit
; ------------------------------------------------------------------------------
print_digit:
    mov temp, r20            ; Move our ASCII character counter into temp
    rcall lcd_data           ; Send it to the LCD
    ret