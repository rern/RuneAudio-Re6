#!/usr/bin/python

import pigpio
from RPLCD.pigpio import CharLCD
from RPLCD.i2c import CharLCD
import sys

lines = sys.argv[ 1 ]

address = 0x27
chip = 'PCF8574'
cols = 20
rows = 4

pi = pigpio.pi()
pin_contrast = 12
contrast = 800
brightness = 800

lcd = CharLCD( chip, address )

lcd = CharLCD( pi, i2c_expander=chip, address=address,
	cols=cold, rows=rows,
	charmap='A02',
	pin_contrast=pin_contrast,
	backlight_pwm=brightness,
	contrast_pwm=contrast )
	
lcd.clear()
lcd.write_string( lines )
lcd.close()
