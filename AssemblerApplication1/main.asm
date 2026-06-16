.include "m328pdef.inc"

.def temp         = r16
.def angle_l      = r24
.def angle_h      = r25

.org 0x0000
    jmp start

.org OVF0addr
    jmp timer0_ovf_isr

.org 0x0034

.include "twi.asm"
.include "as5600.asm"
.include "lcd.asm"
.include "conversion.asm"
.include "led_pwm.asm"

start:
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    rcall led_pwm_init
    sei                      ; Enable global interrupts

    rcall twi_init
    rcall lcd_init

main_loop:
    rcall as5600_read
    rcall led_pwm_update
    
    ldi temp, 0x80           ; Cursor to line 1, pos 0
    rcall lcd_cmd
    rcall convert_display
    
    rcall delay_5ms
    rjmp main_loop