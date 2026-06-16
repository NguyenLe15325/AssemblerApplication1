; ==============================================================================
; I2C LCD Driver (HD44780 + PCF8574)
; ------------------------------------------------------------------------------
; This driver controls a standard 16x2 character LCD that is connected via an
; I2C backpack (PCF8574). It operates the LCD in 4-bit mode to save pins.
; Every byte of data sent to the LCD is split into two 4-bit "nibbles".
; ==============================================================================

.def lcd_mode     = r17                 ; Register to track whether we are sending Data (1) or a Command (0)
.equ LCD_W = 0x4E                       ; I2C Write Address for the PCF8574 (0x27 shifted left by 1)

lcd_init:
    ; 1. The HD44780 requires a specific startup sequence to reliably enter 4-bit mode.
    rcall delay_5ms
    ldi temp, 0x30           ; Wake up command 1
    rcall lcd_nibble
    rcall delay_5ms
    ldi temp, 0x30           ; Wake up command 2
    rcall lcd_nibble
    ldi temp, 0x30           ; Wake up command 3
    rcall lcd_nibble
    ldi temp, 0x20           ; Force 4-bit operational mode
    rcall lcd_nibble
    
    ldi temp, 0x28              ; 2 lines, 5x8 font matrix
    rcall lcd_cmd
    ldi temp, 0x0C              ; Display ON, cursor OFF
    rcall lcd_cmd
    ldi temp, 0x01              ; Clear screen command
    rcall lcd_cmd
    rcall delay_5ms
    ret

lcd_cmd:
    clr lcd_mode
    rjmp lcd_write

lcd_data:
    ldi lcd_mode, 1

lcd_write:
    push temp
    andi temp, 0xF0
    or temp, lcd_mode
    rcall lcd_nibble
    pop temp
    swap temp
    andi temp, 0xF0
    or temp, lcd_mode

lcd_nibble:
    ori temp, 0x08              ; Keep Backlight line permanently HIGH
    mov r18, temp
    ori temp, 0x04              ; Clock Enable pin HIGH
    rcall pcf_send
    mov temp, r18               ; Drop Enable pin LOW
    rcall pcf_send
    ret

pcf_send:
    push temp
    rcall twi_start
    ldi temp, LCD_W
    rcall twi_write
    pop temp
    rcall twi_write
    rcall twi_stop
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