; ==============================================================================
; TWI (Two-Wire Interface / I2C) Driver
; ------------------------------------------------------------------------------
; This file contains the low-level subroutines to control the ATmega328P's
; hardware I2C peripheral. It sets the clock speed and provides functions to
; send Start/Stop conditions, write bytes, and read bytes with ACK/NACK.
; ==============================================================================

twi_init:
    ; Initialize the I2C interface clock speed to 100kHz.
    ; Formula: SCL_freq = CPU_freq / (16 + 2 * TWBR * Prescaler)
    ; 100,000 = 16,000,000 / (16 + 2 * 72 * 1)
    ldi temp, 72              
    sts TWBR, temp            ; Set Bit Rate Register
    clr temp                  
    sts TWSR, temp            ; Set Status Register (Prescaler = 1)
    ret

twi_start:
    ; Send an I2C Start condition to claim the bus.
    ; TWINT: Clears the interrupt flag to start the hardware job.
    ; TWSTA: Generates the START condition on the bus.
    ; TWEN: Enables the TWI hardware.
    ldi temp, (1<<TWINT) | (1<<TWSTA) | (1<<TWEN)
    sts TWCR, temp
    rcall twi_wait            ; Wait until the hardware finishes sending START
    ret

twi_stop:
    ; Send an I2C Stop condition to release the bus.
    ; TWSTO: Generates the STOP condition.
    ldi temp, (1<<TWINT) | (1<<TWSTO) | (1<<TWEN)
    sts TWCR, temp
    ret                       ; No need to wait for STOP condition to finish

twi_write:
    ; Write a single byte of data to the I2C bus.
    ; The data must be loaded into the 'temp' register before calling this.
    sts TWDR, temp            ; Load data into the TWI Data Register
    ldi temp, (1<<TWINT) | (1<<TWEN)
    sts TWCR, temp            ; Start transmission
    rcall twi_wait            ; Wait until the byte has been fully sent
    ret

twi_read_ack:
    ; Read a byte from the bus and respond with an ACK (Acknowledge).
    ; ACK tells the slave device "I received this, send me the next byte".
    ; TWEA: TWI Enable Acknowledge bit.
    ldi temp, (1<<TWINT) | (1<<TWEN) | (1<<TWEA)
    sts TWCR, temp
    rcall twi_wait            ; Wait until the byte is fully received
    lds temp, TWDR            ; Read the received data into 'temp'
    ret

twi_read_nack:
    ; Read a byte from the bus and respond with a NACK (Not Acknowledge).
    ; NACK tells the slave device "I received this, stop sending data".
    ldi temp, (1<<TWINT) | (1<<TWEN)
    sts TWCR, temp
    rcall twi_wait            ; Wait until the byte is fully received
    lds temp, TWDR            ; Read the received data into 'temp'
    ret

twi_wait:
    ; Polls the TWINT (TWI Interrupt Flag) bit in the TWCR register.
    ; The hardware sets this bit HIGH when it finishes its current operation.
    lds temp, TWCR
    sbrs temp, TWINT          ; Skip the next instruction if TWINT is Set (1)
    rjmp twi_wait             ; If not set, loop back and check again
    ret