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

### gpio
#from RPLCD.gpio import CharLCD
#lcd = CharLCD( cols=cols, rows=rows, numbering_mode=GPIO.BOARD, pin_rs=15, pin_rw=18, pin_e=16, pins_data=[21, 22, 23, 24], auto_linebreaks=False )

# assign variables
field = [ '', 'artist', 'title', 'album', 'elapsed', 'total', 'state' ]
for i in range( 1, 7 ):
    exec( field[ i ] +' = "'+ sys.argv[ i ][ :cols ]+'"' )

elapsed = round( float( elapsed ) )
total = round( float( total ) )

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

if state == 'stop':
    lines = artist +'\r\n'+ title
    if rows == 4:
        lines += '\r\n'+ album +'\r\n'+ second2hhmmss( total )
        
    lcd.clear()
    lcd.write_string( lines )
    lcd.close()
    
else:
    hhmmss = second2hhmmss( elapsed )
    progress = second2hhmmss( elapsed )
    if total != 'false':
        total = ' / '+ second2hhmmss( total )
        progress = hhmmss + total
    
    lines = rows == 2 and title +'\r\n'+ progress or artist +'\r\n'+ title +'\r\n'+ album +'\r\n'+ progress
        
    lcd.clear()
    lcd.write_string( lines )
    
    pos = rows -1
    if state == 'play':
        while True:
            time.sleep( 1 )
            
            elapsed += 1
            progress = second2hhmmss( elapsed ) + total
            lcd.cursor_pos = ( pos, 0 )
            lcd.write_string( progress )
    else: # pause
        pausetxt = progress
        pauseblank = ' ' * len( hhmmss )
        
        while True: # blink
            time.sleep( 0.75 )
            
            lcd.cursor_pos = ( pos, 0 )
            lcd.write_string( pauseblank )
            time.sleep( 0.75 )
            lcd.write_string( '\r'+ hhmmss )
