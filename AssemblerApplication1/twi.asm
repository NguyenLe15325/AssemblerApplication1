twi_init:
    ldi temp, 72              ; 100kHz I2C
    sts TWBR, temp
    clr temp                  ; Prescaler = 1
    sts TWSR, temp
    ret

twi_start:
    ldi temp, (1<<TWINT) | (1<<TWSTA) | (1<<TWEN)
    sts TWCR, temp
    rcall twi_wait
    ret

twi_stop:
    ldi temp, (1<<TWINT) | (1<<TWSTO) | (1<<TWEN)
    sts TWCR, temp
    ret

twi_write:
    sts TWDR, temp
    ldi temp, (1<<TWINT) | (1<<TWEN)
    sts TWCR, temp
    rcall twi_wait
    ret

twi_read_ack:
    ldi temp, (1<<TWINT) | (1<<TWEN) | (1<<TWEA)
    sts TWCR, temp
    rcall twi_wait
    lds temp, TWDR
    ret

twi_read_nack:
    ldi temp, (1<<TWINT) | (1<<TWEN)
    sts TWCR, temp
    rcall twi_wait
    lds temp, TWDR
    ret

twi_wait:
    lds temp, TWCR
    sbrs temp, TWINT
    rjmp twi_wait
    ret