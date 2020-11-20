#!/usr/bin/python

import sys
import time
import math

if len( sys.argv ) == 1: quit()

cols = 20
rows = 4
charmap = 'A00'

### i2c
address = 0x27
chip = 'PCF8574'

from RPLCD.i2c import CharLCD
lcd = CharLCD( chip, address )
lcd = CharLCD( cols=cols, rows=rows, charmap=charmap, address=address, i2c_expander=chip, auto_linebreaks=False )

### gpio
#from RPLCD.gpio import CharLCD
#lcd = CharLCD( cols=cols, rows=rows, charmap=charmap, numbering_mode=GPIO.BOARD, pin_rs=15, pin_rw=18, pin_e=16, pins_data=[21, 22, 23, 24], auto_linebreaks=False )

argv1 = sys.argv[ 1 ] # backlight on/off
if argv1 == 'on' or argv1 == 'off':
    lcd.backlight_enabled = argv1 == 'on' and True or False
    quit()

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
logol = (
    0b11111,
    0b11011,
    0b11011,
    0b00000,
    0b11011,
    0b11011,
    0b11111,
    0b11111,
)
logor = (
    0b01110,
    0b10110,
    0b10110,
    0b01110,
    0b01110,
    0b10110,
    0b11010,
    0b11100,
)
dot = (
    0b00000,
    0b00000,
    0b00000,
    0b00110,
    0b00110,
    0b00000,
    0b00000,
    0b00000,
)
lcd.create_char( 0, pause )
lcd.create_char( 1, play )
lcd.create_char( 2, stop )
lcd.create_char( 3, logol )
lcd.create_char( 4, logor )
lcd.create_char( 5, dot )

ipause = '\x00 '
iplay = '\x01 '
istop = '\x02 '
irr = '\x03\x04'
idots = ' \x05  \x05  \x05'
rn = '\r\n'

if len( sys.argv ) == 2: # rr - splash or single argument string (^ = linebreak)
    if argv1 == 'rr':
        file = open( '/srv/http/data/system/version' )
        version = file.read()
        file.close()
        spaces = '       '
        splash = ''
        if rows == 4:
            spaces += '  '
            splash = rn
        splash += spaces + irr + rn + spaces + version
        lcd.write_string( splash )
    else:
        lcd.auto_linebreaks = True
        lcd.clear()
        lcd.write_string( argv1.replace( '^', rn ) )
    lcd.close()
    quit()

lcd.clear()

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

field = [ '', 'artist', 'title', 'album', 'elapsed', 'total', 'state' ] # assign variables
for i in range( 1, 7 ):
    val = sys.argv[ i ][ :cols ].replace( '"', '\\"' ) # escape "
    exec( field[ i ] +' = "'+ val.rstrip() +'"' )      # fix last space error - remove
    
if title == 'false': title = rows == 2 and artist or idots
    
if total != 'false':
    total = round( float( total ) )
    totalhhmmss = second2hhmmss( total )
else:
    total = ''
    totalhhmmss = ''
    
elapsed = elapsed != 'false' and round( float( elapsed ) )
elapsedhhmmss = elapsed and second2hhmmss( elapsed )

if state == 'stop':
    progress = totalhhmmss
else:
    slash = cols == 20 and ' / ' or '/'
    totalhhmmss = total and slash + totalhhmmss
    progress = elapsedhhmmss + totalhhmmss

istate = state == 'stop' and  istop or ( state == 'pause' and ipause or iplay )
progress = istate + progress

progl = len( progress )
if progl <= cols - 3: progress += ' ' * ( cols - progl - 2 ) + irr

if artist == 'false': artist = idots
lines = rows == 2 and title or artist + rn + title + rn + album

lcd.write_string( lines + rn + progress[ :cols ] )
lcd.close()
    
if state == 'stop' or state == 'pause': quit()

row = rows - 1
while True: # play
    time.sleep( 1 )
    
    elapsed += 1
    progress = iplay + second2hhmmss( elapsed ) + totalhhmmss
    if len( progress ) > 17: progress += '  '
    lcd.cursor_pos = ( row, 0 )
    lcd.write_string( progress[ :cols ] )
    