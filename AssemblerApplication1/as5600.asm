; ==============================================================================
; AS5600 Magnetic Encoder Driver
; ------------------------------------------------------------------------------
; The AS5600 is an I2C magnetic sensor that provides a 12-bit absolute angle.
; The 12-bit angle (0-4095) is split across two registers inside the AS5600:
; - Register 0x0C contains the Upper 4 bits (Bits 11-8)
; - Register 0x0D contains the Lower 8 bits (Bits 7-0)
; ==============================================================================

as5600_read:
    ; 1. Tell the AS5600 we want to set the internal register pointer.
    rcall twi_start
    ldi temp, 0x6C           ; 0x6C is the AS5600 I2C Address in Write mode
    rcall twi_write
    
    ; 2. Point to the RAW ANGLE MSB register (0x0C).
    ldi temp, 0x0C           
    rcall twi_write
    
    ; 3. Send a "Repeated Start" to switch from Write mode to Read mode.
    rcall twi_start
    ldi temp, 0x6D           ; 0x6D is the AS5600 I2C Address in Read mode
    rcall twi_write
    
    ; 4. Read the first byte (Register 0x0C).
    ; We respond with ACK to tell the AS5600 to auto-increment to 0x0D.
    rcall twi_read_ack
    mov angle_h, temp
    andi angle_h, 0x0F       ; The top 4 bits of 0x0C are unused, so we mask them to zero.
    
    ; 5. Read the second byte (Register 0x0D).
    ; We respond with NACK to tell the AS5600 we are done reading.
    rcall twi_read_nack
    mov angle_l, temp
    
    ; 6. Send the STOP condition to release the I2C bus.
    rcall twi_stop
    ret