; ==============================================================================
; I2C LCD Driver (HD44780 + PCF8574)
; ------------------------------------------------------------------------------
; This driver controls a standard 16x2 character LCD connected via an I2C backpack.
; The backpack uses a PCF8574 chip, which has 8 output pins (P7 to P0).
;
; How the PCF8574 connects to the LCD pins:
; P7 = LCD D7 (Data 7)
; P6 = LCD D6 (Data 6)
; P5 = LCD D5 (Data 5)
; P4 = LCD D4 (Data 4)
; P3 = LCD Backlight (1 = ON)
; P2 = LCD EN (Enable pulse)
; P1 = LCD RW (Read/Write, we always keep it 0 for Write)
; P0 = LCD RS (Register Select: 0 = Command, 1 = Data)
; ==============================================================================

.def lcd_mode = r17        ; Holds the RS bit (0 for Command, 1 for Data)
.equ LCD_W    = 0x4E       ; I2C Address of the PCF8574 (0x27 shifted left by 1)

lcd_init:
    ; 1. The LCD needs time to power up
    rcall delay_5ms
    
    ; 2. Send "Wake Up" sequence to force the LCD into 4-bit mode.
    ldi temp, 0x30
    rcall lcd_nibble
    rcall delay_5ms
    
    ldi temp, 0x30
    rcall lcd_nibble
    
    ldi temp, 0x30
    rcall lcd_nibble
    
    ldi temp, 0x20           ; Finally, switch to 4-bit mode
    rcall lcd_nibble
    
    ; 3. Now in 4-bit mode, we can send full 8-bit commands!
    ldi temp, 0x28           ; 2 lines, 5x8 font matrix
    rcall lcd_cmd
    
    ldi temp, 0x0C           ; Display ON, cursor OFF
    rcall lcd_cmd
    
    ldi temp, 0x01           ; Clear screen
    rcall lcd_cmd
    
    rcall delay_5ms
    ret

; ------------------------------------------------------------------------------
; Send a Command to the LCD
; ------------------------------------------------------------------------------
lcd_cmd:
    clr lcd_mode             ; RS = 0 (Command)
    rcall lcd_write
    ret

; ------------------------------------------------------------------------------
; Send Data (a character) to the LCD
; ------------------------------------------------------------------------------
lcd_data:
    ldi lcd_mode, 1          ; RS = 1 (Data)
    rcall lcd_write
    ret

; ------------------------------------------------------------------------------
; Write a full 8-bit byte to the LCD in 4-bit mode
; ------------------------------------------------------------------------------
lcd_write:
    ; We must send the High 4 bits first, then the Low 4 bits.
    
    ; --- Send High Nibble ---
    push temp                ; Save the original 8-bit byte
    andi temp, 0xF0          ; Keep only the High 4 bits (D7-D4)
    or temp, lcd_mode        ; Attach the RS bit (Command or Data)
    rcall lcd_nibble         ; Send it!
    
    ; --- Send Low Nibble ---
    pop temp                 ; Retrieve the original 8-bit byte
    swap temp                ; Swap the High and Low 4 bits
    andi temp, 0xF0          ; Keep only the new High 4 bits
    or temp, lcd_mode        ; Attach the RS bit (Command or Data)
    rcall lcd_nibble         ; Send it!
    
    ret

; ------------------------------------------------------------------------------
; Send a 4-bit nibble to the PCF8574 and pulse the Enable pin
; ------------------------------------------------------------------------------
lcd_nibble:
    ori temp, 0x08           ; Turn ON the Backlight bit (P3 = 1)
    
    ; --- Pulse Enable (EN) HIGH ---
    ori temp, 0x04           ; Turn ON the Enable bit (P2 = 1)
    rcall pcf_send           ; Send the payload over I2C
    
    ; --- Pulse Enable (EN) LOW ---
    andi temp, 0xFB          ; Turn OFF the Enable bit (P2 = 0) by masking with 11111011
    rcall pcf_send           ; Send the payload over I2C
    
    ret

; ------------------------------------------------------------------------------
; Send the final byte over I2C to the PCF8574
; ------------------------------------------------------------------------------
pcf_send:
    push temp
    
    rcall twi_start          ; Start I2C
    
    ldi temp, LCD_W          ; Send PCF8574 Address
    rcall twi_write
    
    pop temp                 ; Send our data payload
    rcall twi_write
    
    rcall twi_stop           ; Stop I2C
    
    rcall delay_40us         ; The LCD needs a tiny delay to process the data
    ret

; ------------------------------------------------------------------------------
; Delay Routines
; ------------------------------------------------------------------------------
delay_40us:
    ldi r19, 210
d40:
    dec r19
    brne d40
    ret

delay_5ms:
    ldi r18, 120
d5:
    rcall delay_40us
    dec r18
    brne d5
    ret