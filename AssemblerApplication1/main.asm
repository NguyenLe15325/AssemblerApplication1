; ==============================================================================
; Main Program Entry
; ------------------------------------------------------------------------------
; This file is the orchestrator of the entire project. It sets up the interrupts,
; initializes all the hardware modules (I2C, LCD, Timer0), and runs the main loop.
; The main loop continuously reads the magnetic encoder, updates the LED brightness
; using software PWM, and prints the raw angle value to the I2C LCD.
; ==============================================================================
.include "m328pdef.inc"

; --- Global Register Definitions ---
; We define named registers to make the code easier to read.
.def temp         = r16    ; A general purpose register used for quick operations
.def angle_l      = r24    ; Will hold the lower 8 bits of the AS5600 angle
.def angle_h      = r25    ; Will hold the upper 4 bits of the AS5600 angle

; --- Interrupt Vector Table ---
; AVR microcontrollers start execution at address 0x0000.
; We place "jump" instructions here to redirect the CPU to our actual code.
.org 0x0000
    jmp start              ; Vector 1: Reset vector (Power on / Reset button)

; Timer0 Overflow vector is located at word address 0x0020 (defined as OVF0addr).
; It fires whenever Timer0 counts past 255.
.org OVF0addr
    jmp timer0_ovf_isr     ; Vector 17: Timer0 Overflow vector

; Safely place our main code after the interrupt vector table (which ends at 0x0032).
.org 0x0034                

; --- Module Includes ---
; Including these files physically pastes their subroutines into this spot.
.include "twi.asm"         ; I2C/TWI hardware driver
.include "as5600.asm"      ; AS5600 Magnetic Encoder I2C driver
.include "lcd.asm"         ; HD44780 I2C LCD screen driver
.include "conversion.asm"  ; Converts binary numbers to ASCII characters
.include "led_pwm.asm"     ; Software PWM logic for the built-in LED

; --- Main Initialization ---
start:
    ; 1. Initialize the Stack Pointer. This is required before using 'rcall' or 'push/pop'.
    ; We set it to point to the very end of SRAM (RAMEND).
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    ; 2. Initialize the software PWM module (sets up Timer0 and the LED output pin)
    rcall led_pwm_init     
    
    ; 3. Enable Global Interrupts. Without this, the Timer0 interrupt will never fire!
    sei                    

    ; 4. Initialize external I2C hardware
    rcall twi_init         ; Setup the microcontroller's I2C hardware to 100kHz
    rcall lcd_init         ; Send initialization commands to the LCD screen

; --- Main Execution Loop ---
main_loop:
    ; Step 1: Read the absolute magnetic encoder position (0 - 4095)
    ; This subroutine populates the 'angle_h' and 'angle_l' registers.
    rcall as5600_read
    
    ; Step 2: Map the 12-bit position to an 8-bit LED brightness (0 - 255)
    ; This calculates the brightness level for the Timer0 ISR to use.
    rcall led_pwm_update
    
    ; Step 3: Update the LCD with the raw encoder value
    ldi temp, 0x80         ; 0x80 is the LCD command to set cursor to Line 1, Position 0
    rcall lcd_cmd          ; Send the command
    rcall convert_display  ; Convert the angle to digits and print them
    
    ; Step 4: Brief delay to stabilize the LCD and I2C bus before the next read
    rcall delay_5ms
    
    ; Repeat forever!
    rjmp main_loop