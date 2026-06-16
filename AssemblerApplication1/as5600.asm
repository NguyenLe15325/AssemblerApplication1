as5600_read:
    rcall twi_start
    ldi temp, 0x6C           ; AS5600 Write Address
    rcall twi_write
    ldi temp, 0x0C           ; RAW ANGLE Register Address
    rcall twi_write
    
    rcall twi_start
    ldi temp, 0x6D           ; AS5600 Read Address
    rcall twi_write
    
    rcall twi_read_ack
    mov angle_h, temp
    andi angle_h, 0x0F
    
    rcall twi_read_nack
    mov angle_l, temp
    
    rcall twi_stop
    ret