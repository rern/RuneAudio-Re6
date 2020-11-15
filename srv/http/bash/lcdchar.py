#!/usr/bin/python

import sys
import time
import math

cols = 20
rows = 4

### i2c
address = 0x27
chip = 'PCF8574'

from RPLCD.i2c import CharLCD
lcd = CharLCD( chip, address )

lcd = CharLCD( cols=cols, rows=rows, address=address, i2c_expander=chip, auto_linebreaks=False )

if len( sys.argv ) == 1: # no args - off backlight
    lcd.backlight_enabled = False
    quit()

### gpio
#from RPLCD.gpio import CharLCD
#lcd = CharLCD( cols=cols, rows=rows, numbering_mode=GPIO.BOARD, pin_rs=15, pin_rw=18, pin_e=16, pins_data=[21, 22, 23, 24], auto_linebreaks=False )

# assign variables
field = [ '', 'artist', 'title', 'album', 'elapsed', 'total', 'state' ]
for i in range( 1, 7 ):
    exec( field[ i ] +' = "'+ sys.argv[ i ][ :cols ]+'"' )

if not artist and not title and not album:
    lcd.clear()
    lcd.write_string( '\r\n   RuneAudio+R e6' )
    lcd.close()
    quit()
    
elapsed = round( float( elapsed ) )
total = total != 'false' and round( float( total ) )

pause = (
    0b00000,
    0b11011,
    0b11011,
    0b11011,
    0b11011,
    0b11011,
    0b00000,
    0b00000,
)
play = (
    0b10000,
    0b11000,
    0b11100,
    0b11110,
    0b11100,
    0b11000,
    0b10000,
    0b00000,
)
stop = (
    0b00000,
    0b11111,
    0b11111,
    0b11111,
    0b11111,
    0b11111,
    0b00000,
    0b00000,
)

lcd.create_char( 0, pause )
lcd.create_char( 1, play )
lcd.create_char( 2, stop )
ipause = '\x00 '
iplay = '\x01 '
istop = '\x02 '
rn = '\r\n'

def second2hhmmss( sec ):
    hh = math.floor( sec / 3600 )
    mm = math.floor( ( sec % 3600 ) / 60 )
    ss = sec % 60
    HH = hh > 0 and str( hh ) +':' or ''
    mmt = str( mm )
    MM = hh > 0 and ( mm > 9 and mmt +':' or '0'+ mmt +':' ) or ( mm > 0 and mmt +':' or '' )
    sst = str( ss )
    SS = mm > 0 and ( ss > 9 and sst or '0'+ sst ) or sst
    return HH + MM + SS

lcd.clear()

if state == 'stop':
    lines = artist + rn + title
    if rows == 4:
        lines += rn + album + rn + istop
    if total:
        lines += second2hhmmss( total )
        
    lcd.write_string( lines )
    lcd.close()
    quit()
    
hhmmss = second2hhmmss( elapsed )
progress = second2hhmmss( elapsed )
if total:
    totalhhmmss = ' / '+ second2hhmmss( total )
    progress += totalhhmmss
else:
    totalhhmmss = ''
    
lines = rows == 2 and title or artist + rn + title + rn + album

if state == 'pause':
    lines += rn + ipause + progress
    lcd.write_string( lines )
    lcd.close()
    quit()

# play
lines += rn + iplay + progress
lcd.write_string( lines )
pos = rows -1
while True:
    time.sleep( 1 )
    
    elapsed += 1
    progress = iplay + second2hhmmss( elapsed ) + totalhhmmss
    lcd.cursor_pos = ( pos, 0 )
    lcd.write_string( progress )
    