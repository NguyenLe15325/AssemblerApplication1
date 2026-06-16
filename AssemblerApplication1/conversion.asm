; ==============================================================================
; Binary to Decimal Conversion
; ------------------------------------------------------------------------------
; This module converts our 12-bit binary angle (a number between 0 and 4095)
; into printable ASCII characters to display on the LCD.
; 
; This implementation initializes the ASCII counter to '0' directly,
; executing the subtraction first and incrementing only on success.
; ==============================================================================

convert_display:
    
    ; --------------------------------------------------------------------------
    ; 1. EXTRACT THOUSANDS DIGIT
    ; --------------------------------------------------------------------------
    ldi r20, '0'              ; Start directly at ASCII '0'

count_1000s:
    subi angle_l, low(1000)   ; Subtract first
    sbci angle_h, high(1000)
    brcs restore_1000s        ; If Carry SET (< 0), we overshot! Go repair.
    
    inc r20                   ; Subtraction succeeded, increment digit
    rjmp count_1000s          ; Loop back to try again

restore_1000s:
    ldi temp, low(1000)       ; Add 1000 back to repair the remainder
    add angle_l, temp
    ldi temp, high(1000)
    adc angle_h, temp
    
    rcall print_digit
    
    
    ; --------------------------------------------------------------------------
    ; 2. EXTRACT HUNDREDS DIGIT
    ; --------------------------------------------------------------------------
    ldi r20, '0'              ; Start directly at ASCII '0'

count_100s:
    subi angle_l, low(100)    ; Subtract first
    sbci angle_h, high(100)
    brcs restore_100s         ; If Carry SET (< 0), we overshot! Go repair.
    
    inc r20                   ; Subtraction succeeded, increment digit
    rjmp count_100s           ; Loop back to try again

restore_100s:
    ldi temp, low(100)        ; Add 100 back to repair the remainder
    add angle_l, temp
    ldi temp, high(100)
    adc angle_h, temp
    
    rcall print_digit
    
    
    ; --------------------------------------------------------------------------
    ; 3. EXTRACT TENS DIGIT
    ; --------------------------------------------------------------------------
    ldi r20, '0'              ; Start directly at ASCII '0'

count_10s:
    subi angle_l, 10          ; Subtract first
    sbci angle_h, 0
    brcs restore_10s          ; If Carry SET (< 0), we overshot! Go repair.
    
    inc r20                   ; Subtraction succeeded, increment digit
    rjmp count_10s            ; Loop back to try again

restore_10s:
    ldi temp, 10              ; Add 10 back to repair the remainder
    add angle_l, temp
    ldi temp, 0
    adc angle_h, temp
    
    rcall print_digit
    
    
    ; --------------------------------------------------------------------------
    ; 4. PRINT ONES DIGIT
    ; --------------------------------------------------------------------------
    ; Whatever remains in angle_l IS the ones digit (0 to 9)
    mov temp, angle_l
    ldi r20, '0'
    add temp, r20             ; Convert number to ASCII character
    rcall lcd_data
    
    ret


; ------------------------------------------------------------------------------
; Helper Subroutine: Print Digit
; ------------------------------------------------------------------------------
print_digit:
    mov temp, r20             ; Move our ASCII character counter into temp
    rcall lcd_data            ; Send it to the LCD
    ret