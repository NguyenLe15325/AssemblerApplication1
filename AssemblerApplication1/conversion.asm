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
    ldi r20, '0' - 1         ; Set our digit counter to the ASCII character just before '0'
                             ; (It will immediately become '0' on the first loop)

count_1000s:
    inc r20                  ; Increment our digit counter ('0' -> '1' -> '2'...)
    
    ; Subtract 1000 from our 16-bit number (angle_h : angle_l)
    subi angle_l, low(1000)  ; Subtract lower 8 bits of 1000
    sbci angle_h, high(1000) ; Subtract upper 8 bits of 1000 (with carry from previous step)
    
    brcc count_1000s         ; Branch if Carry Cleared (meaning the result is still >= 0)
                             ; If >= 0, loop back and subtract 1000 again!
                             
    ; If we got here, the result dropped below 0! We subtracted 1000 one time too many.
    ; So we simply add 1000 back to the number to repair the damage.
    ldi temp, low(1000)
    add angle_l, temp
    ldi temp, high(1000)
    adc angle_h, temp
    
    rcall print_digit        ; Print the thousands digit to the LCD
    
    
    ; --------------------------------------------------------------------------
    ; 2. EXTRACT HUNDREDS DIGIT
    ; --------------------------------------------------------------------------
    ldi r20, '0' - 1         ; Reset digit counter

count_100s:
    inc r20
    
    subi angle_l, low(100)   ; Subtract 100
    sbci angle_h, high(100)
    
    brcc count_100s          ; If >= 0, loop back and subtract 100 again
    
    ; We went below 0! Add 100 back to repair.
    ldi temp, low(100)
    add angle_l, temp
    ldi temp, high(100)
    adc angle_h, temp
    
    rcall print_digit        ; Print the hundreds digit to the LCD
    
    
    ; --------------------------------------------------------------------------
    ; 3. EXTRACT TENS DIGIT
    ; --------------------------------------------------------------------------
    ldi r20, '0' - 1         ; Reset digit counter

count_10s:
    inc r20
    
    subi angle_l, 10         ; Subtract 10
    sbci angle_h, 0
    
    brcc count_10s           ; If >= 0, loop back and subtract 10 again
    
    ; We went below 0! Add 10 back to repair.
    ldi temp, 10
    add angle_l, temp
    ldi temp, 0
    adc angle_h, temp
    
    rcall print_digit        ; Print the tens digit to the LCD
    
    
    ; --------------------------------------------------------------------------
    ; 4. PRINT ONES DIGIT
    ; --------------------------------------------------------------------------
    ; After extracting 1000s, 100s, and 10s, whatever remains in angle_l 
    ; IS the ones digit! (It will be a number between 0 and 9)
    
    mov temp, angle_l        ; Move the remaining number into temp
    
    ldi r21, '0'
    add temp, r21            ; Add the ASCII value of '0' to convert it to a printable character
    
    rcall lcd_data           ; Print the final digit
    
    ret                      ; Conversion complete!


; ------------------------------------------------------------------------------
; Helper Subroutine: Print Digit
; ------------------------------------------------------------------------------
print_digit:
    mov temp, r20            ; Move our ASCII character counter into temp
    rcall lcd_data           ; Send it to the LCD
    ret