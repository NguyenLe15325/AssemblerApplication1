; P7 = LCD D7 (Data 7)
; P6 = LCD D6 (Data 6)
; P5 = LCD D5 (Data 5)
; P4 = LCD D4 (Data 4)
; P3 = LCD Backlight (1 = ON)
; P2 = LCD EN (Enable pulse)
; P1 = LCD RW (Read/Write, we always keep it 0 for Write)
; P0 = LCD RS (Register Select: 0 = Command, 1 = Data)
.def lcd_mode = r17
.equ LCD_W    = 0x4E

lcd_init:
    rcall delay_5ms
    
    ldi temp, 0x30
    rcall lcd_nibble
    rcall delay_5ms
    
    ldi temp, 0x30
    rcall lcd_nibble
    
    ldi temp, 0x30
    rcall lcd_nibble
    
    ldi temp, 0x20
    rcall lcd_nibble
    
    ldi temp, 0x28
    rcall lcd_cmd
    
    ldi temp, 0x0C
    rcall lcd_cmd
    
    ldi temp, 0x01
    rcall lcd_cmd
    
    rcall delay_5ms
    ret

lcd_cmd:
    clr lcd_mode	; RS = 0 (Command)
    rcall lcd_write
    ret

lcd_data:
    ldi lcd_mode, 1		; RS = 1 (Data)
    rcall lcd_write
    ret

lcd_write:
	; Send high nibble
    push temp
    andi temp, 0xF0
    or temp, lcd_mode
    rcall lcd_nibble
    ; Send low nibble
    pop temp
    swap temp
    andi temp, 0xF0
    or temp, lcd_mode
    rcall lcd_nibble
    ret

lcd_nibble:
    ori temp, 0x08	; Turn ON the Backlight bit (P3 = 1)
    mov r18, temp
    ori temp, 0x04	; Turn ON the Enable bit (P2 = 1)
    rcall pcf_send
    mov temp, r18
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
    rcall delay_40us
    ret

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