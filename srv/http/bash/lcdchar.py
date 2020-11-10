#!/usr/bin/python

from RPLCD.i2c import CharLCD
from RPLCD.gpio import CharLCD
import sys

lines = sys.argv[ 1 ]  # display strings (\r\n as newline)

cols = 20          # 40, 20, 16
rows = 4           # 4, 2

# i2c
address = 0x27     # get with command: i2cdetect 1
chip = 'PCF8574'   # PCF8574, MCP23008, MCP23017
lcd = CharLCD( chip, address )
lcd = CharLCD( cols=cold, rows=rows, charmap='A02', address=address, i2c_expander=chip )

# gpio
#lcd = CharLCD( cols=cols, rows=rows, charmap='A02', numbering_mode=GPIO.BOARD, pin_rs=15, pin_rw=18, pin_e=16, pins_data=[21, 22, 23, 24] )
	
lcd.clear()
lcd.write_string( lines )
lcd.close()
