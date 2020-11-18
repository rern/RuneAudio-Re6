$( function() { // document ready start >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

function rebootText( enable, device ) {
	G.reboot = G.reboot.filter( function( el ) {
		return el.indexOf( device ) === -1
	} );
	G.reboot.push( enable +' '+ device );
}
function renderStatus() {
	var undervoltage = '';
	var warning = '<i style="width: 20px; text-align: center" class="fa fa-warning blink"></i>';
	if ( G.undervoltage ) {
		undervoltage = '<br><red>'+ warning +'</red> Voltage under 4.7V';
	} else if ( G.undervdetected ) {
		undervoltage = '<br>'+ warning +' Voltage under 4.7V occured';
	}
	return G.cpuload
		+'<br>'+ ( G.cputemp < 80 ? G.cputemp +' °C' : '<red>'+ warning + G.cputemp +' °C</red>' )
		+'<br>'+ G.time
		+'<br>'+ G.uptime
		+'<br>'+ G.startup
		+ undervoltage
}

refreshData = function() {
	bash( '/srv/http/bash/system-data.sh', function( list ) {
		G = list;
		G.reboot = list.reboot ? list.reboot.split( '\n' ) : [];
		var systemlabel =
			 'RuneAudio<br>'
			+'Hardware<br>'
			+'SoC<br>'
			+'Output Device<br>'
			+'Kernel<br>'
			+'<span class="settings" data-setting="mpd">MPD<i class="fa fa-gear"></i></span><br>'
			+'<span class="settings" data-setting="networks">Network<i class="fa fa-gear"></i></span>';
		var statuslabel =
			 'CPU Load<br>'
			+'CPU Temperatue<br>'
			+'Time<br>'
			+'Up Time<br>'
			+'Startup';
		var bullet = ' <gr>&bull;</gr> ';
		if ( G.ip ) {
			var ip = G.ip.split( ',' );
			var iplist = '';
			ip.forEach( function( el ) {
				var val = el.split( ' ' ); // [ interface, mac, ip ]
				if ( val[ 2 ] ) {
					iplist += '<i class="fa fa-'+ ( val[ 0 ] === 'eth0' ? 'lan' : 'wifi-3' ) +' gr"></i>&ensp;';
					iplist += val[ 1 ] +'<span class="wide">&emsp;<gr>'+ val[ 2 ] +'</gr></span><br>';
					systemlabel += '<br>';
					if ( !G.streamingip ) G.streamingip = val[ 1 ];
				}
			} )
		}
		G.sources.pop(); // remove autoupdate
		G.sources.pop(); // remove reboot
		systemlabel += '<span class="settings" data-setting="sources">Sources<i class="fa fa-gear"></i></span>';
		var sourcelist = '';
		$.each( G.sources, function( i, val ) {
			sourcelist += '<i class="fa fa-'+ val.icon +' gr"></i>&ensp;'+ val.mountpoint.replace( '/mnt/MPD/USB/', '' );
			sourcelist += ( val.size ? bullet + val.size : '' ) +'<br>';
			systemlabel += '<br>';
		} );
		$( '#systemlabel' ).html( systemlabel );
		var mpdstats = '';
		if ( G.mpdstats ) {
		var counts = G.mpdstats.split( ' ' );
		var mpdstats = '<span class="wide">&emsp;<i class="fa fa-music gr"></i>&nbsp;'+ Number( counts[ 0 ] ).toLocaleString()
					  +'&ensp;<i class="fa fa-album gr"></i>&ensp;'+ Number( counts[ 1 ] ).toLocaleString()
					  +'&ensp;<i class="fa fa-artist gr"></i> '+ Number( counts[ 2 ] ).toLocaleString() +'</span>';
		}
		$( '#system' ).html(
			  '<i class="fa fa-plus-r gr" style="line-height: 20px;"></i> '+ G.version +' <gr>'+ G.versionui +'</gr>'+ bullet + G.hostname +'<br>'
			+ G.hardware +'<br>'
			+ G.soc +'<br>'
			+ '<span id="output">'+ G.audiooutput +'</span><br>'
			+ G.kernel +'<br>'
			+ G.mpd + mpdstats
			+'<br>'
			+ iplist
			+ sourcelist
		);
		$( '#statuslabel' ).html( statuslabel );
		$( '#status' ).html( renderStatus );
		$( '#onboardaudio' ).prop( 'checked', G.onboardaudio );
		$( '#bluetooth' ).prop( 'checked', G.bluetooth );
		$( '#setting-bluetooth' ).toggleClass( 'hide', !G.bluetooth );
		$( '#wlan' ).prop( 'checked', G.wlan );
		$( '#i2smodule' ).val( 'none' );
		$( '#i2smodule option' ).filter( function() {
			var $this = $( this );
			return $this.text() === G.audiooutput && $this.val() === G.audioaplayname;
		} ).prop( 'selected', true );
		$( '#i2smodule' ).selectric( 'refresh' );
		var i2senabled = $( '#i2smodule' ).val() === 'none' ? false : true;
		$( '#divi2smodulesw' ).toggleClass( 'hide', i2senabled );
		$( '#divi2smodule' ).toggleClass( 'hide', !i2senabled );
		$( '#eth0help' ).toggleClass( 'hide', G.ip.slice( 0, 4 ) !== 'eth0' );
		$( '#lcdchar' ).prop( 'checked', G.lcdchar );
		$( '#setting-lcdchar' ).toggleClass( 'hide', !G.lcdchar );
		$( '#lcd' ).prop( 'checked', G.lcd );
		$( '#setting-lcd' ).toggleClass( 'hide', !G.lcd );
		$( '#relays' ).prop( 'checked', G.relays );
		$( '#setting-relays' ).toggleClass( 'hide', !G.relays );
		$( '#hostname' ).val( G.hostname );
		$( '#timezone' )
			.val( G.timezone )
			.selectric( 'refresh' );
		[ 'ifconfig', 'configtxt', 'journalctl' ].forEach( function( id ) {
			codeToggle( id, 'status' );
		} );
		$( '#soundprofile' ).prop( 'checked', G.soundprofile !== '' );
		$( '#setting-soundprofile' ).toggleClass( 'hide', G.soundprofile === '' );
		resetLocal();
		showContent();
	}, 'json' );
}
refreshData();
//---------------------------------------------------------------------------------------
$( '#timezone, #i2smodule' ).selectric( { maxHeight: 400 } );
$( '.selectric-input' ).prop( 'readonly', 1 ); // fix - suppress screen keyboard

$( '.container' ).on( 'click', '.settings', function() {
	location.href = 'settings.php?p='+ $( this ).data( 'setting' );
} );
$( 'body' ).on( 'click touchstart', function( e ) {
	if ( !$( e.target ).closest( '.i2s' ).length && $( '#i2smodule option:selected' ).val() === 'none' ) {
		$( '#divi2smodulesw' ).removeClass( 'hide' );
		$( '#divi2smodule' ).addClass( 'hide' );
	}
} );
$( '#refresh' ).click( function( e ) {
	if ( $( e.target ).hasClass( 'help' ) ) return
	
	var $this = $( this );
	var active = $this.find( '.fa-refresh' ).hasClass( 'blink' );
	$this.find( '.fa-refresh' ).toggleClass( 'blink', !active );
	if ( active ) {
		clearInterval( intervalcputime );
		bannerHide();
	} else {
		intervalcputime = setInterval( function() {
			bash( '/srv/http/bash/system-data.sh status', function( status ) {
				$.each( status, function( key, val ) {
					G[ key ] = val;
				} );
				$( '#status' ).html( renderStatus );
			}, 'json' );
		}, 10000 );
		banner( 'System Status', 'Refresh every 10 seconds.<br>Click again to stop.', 'sliders', 10000 );
	}
} );
$( '#onboardaudio' ).click( function() {
	if ( $( '#i2smodule' ).val() === 'none' ) {
		info( {
			  icon    : 'volume'
			, title   : 'On-board Audio'
			, message : 'No I²S Module installed.'
						+'<br>On-board audio cannot be disabled.'
		} );
		$( this ).prop( 'checked', true )
		return
	}
	
	var onboardaudio = $( this ).prop( 'checked' );
	if ( !onboardaudio && G.audioaplayname.slice( 0, 7 ) === 'bcm2835' ) {
		info( {
			  icon    : 'volume'
			, title   : 'On-board Audio'
			, message : 'On-board audio is currently in used.'
		} );
		$( '#onboardaudio' ).prop( 'checked', 1 );
	} else {
		G.onboardaudio = onboardaudio;
		rebootText( onboardaudio ? 'Enable' : 'Disable', 'on-board audio' );
		local = 1;
		bash( [ 'onboardaudio', G.onboardaudio, G.reboot.join( '\n' ) ] );
	}
} );
$( '#bluetooth' ).click( function() {
	G.bluetooth = $( this ).prop( 'checked' );
	rebootText( G.bluetooth ? 'Enable' : 'Disable', 'on-board Bluetooth' );
	notify( 'On-board Bluetooth', G.bluetooth, 'bluetooth' );
	bash( [ 'bluetooth', G.bluetooth, G.reboot.join( '\n' ) ] );
} );
$( '#setting-bluetooth' ).click( function() {
	info( {
		  icon     : 'bluetooth'
		, title    : 'On-board Bluetooth'
		, checkbox : { Discoverable: 1 }
		, checked  : ( G.btdiscoverable ? 0 : 1 )
		, ok       : function() {
			G.btdiscoverable = $( '#infoCheckBox input' ).prop( 'checked' );
			notify( 'Bluetooth Discoverable', G.btdiscoverable, 'bluetooth' );
			bash( [ 'btdiscoverable', ( G.btdiscoverable ? 'yes' : 'no' ) ] );
		}
	} );
} );
$( '#wlan' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( !$( '#system .fa-wifi-3' ).length ) {
		notify( 'On-board Wi-Fi', checked, 'wifi-3' );
		bash( [ 'wlan', checked ] );
	} else {
		info( {
			  icon    : 'wifi-3'
			, title   : 'On-board Wi-Fi'
			, message : 'This will disconnect Wi-Fi from router.'
						+'<br>Continue?'
			, cancel  : function() {
				$( '#wlan' ).prop( 'checked', 1 );
			}
			, ok      : function() {
				notify( 'On-board Wi-Fi', false, 'wifi-3' );
				bash( [ 'wlan', false ] );
			}
		} );
	}
} );
$( '#i2smodulesw' ).click( function() {
	// delay to show switch sliding
	setTimeout( function() {
		$( '#i2smodulesw' ).prop( 'checked', 0 );
		$( '#divi2smodulesw' ).addClass( 'hide' );
		$( '#divi2smodule' )
			.removeClass( 'hide' )
			.find( '.selectric' ).click();
	}, 200 );
} );
$( '#i2smodule' ).on( 'selectric-change', function() {
	var audioaplayname = $( this ).val();
	var audiooutput = $( this ).find( ':selected' ).text();
	local = 1;
	if ( audioaplayname !== 'none' ) {
		G.audioaplayname = audioaplayname;
		G.audiooutput = audiooutput;
		G.onboardaudio = false;
		$( '#onboardaudio' ).prop( 'checked', 0 );
		$( '#divi2smodulesw' ).addClass( 'hide' );
		$( '#divi2smodule, #divonboardaudio' ).removeClass( 'hide' );
		rebootText( 'Enable', 'Audio I&#178;S Module' );
		notify( 'I&#178;S Module', 'Enable ...', 'volume' );
	} else {
		var audioaplayname = G.audioaplayname;
		var notrpi0 = G.hardware.split( ' ' )[ 2 ] !== 'Zero';
		if ( notrpi0 ) {
			G.audiooutput = 'On-board - Headphone';
			G.audioaplayname = 'bcm2835 Headphones';
		} else {
			G.audiooutput = 'On-board - HDMI';
			G.audioaplayname = 'bcm2835 HDMI 1';
		}
		G.onboardaudio = true;
		$( '#onboardaudio' ).prop( 'checked', 1 );
		$( '#divi2smodulesw' ).removeClass( 'hide' );
		$( '#divi2smodule, #divonboardaudio' ).addClass( 'hide' );
		rebootText( 'Disable', 'Audio I&#178;S Module' );
		notify( 'I&#178;S Module', 'Disable ...', 'volume' );
	}
	bash( [ 'i2smodule', G.audioaplayname, G.audiooutput, G.reboot.join( '\n' ) ] );
	$( '#output' ).text( G.audiooutput );
} );
$( '#lcdchar' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( checked ) {
		$( '#setting-lcdchar' ).click();
	} else {
		notify( "Character LCD", 'Disable ...', 'gear' );
		rebootText( 'Disble', 'Character LCD' );
		bash( [ 'lcdchardisable' ], G.reboot.join( '\n' ) );
	}
} );
var infolcdchar = heredoc( function() { /*
	<div class="infotextlabel">
		<a class="infolabel">Size</a>
		<a class="infolabel">Interface</a>
		<a class="infolabel">Character Map</a>
	</div>
	<div class="infotextbox" style="width: 220px">
		<div id="cols" class="infocontent infohtml">
			<label><input type="radio" name="size" value="16"> 16x2</label>&ensp;
			<label><input type="radio" name="size" value="20"> 20x4</label>&ensp;
			<label><input type="radio" name="size" value="40"> 40x4</label>
		</div>
		<div id="inf" class="infocontent infohtml">
			<label><input type="radio" name="interface" value="i2c"> I&#178;C</label>&ensp;<px20/>
			<label><input type="radio" name="interface" value="gpio"> GPIO</label><px70/>
		</div>
		<select class="infohtml" id="charmap">
			<option value="A00">A00</option>
			<option value="A02">A02</option>
		</select>
	</div>
	<br>
	<div id="divi2c" style="padding-right: 53px">
		<div class="infotextlabel">
			<a class="infolabel">Expander</a>
			<a class="infolabel">Address</a>
		</div>
		<div class="infotextbox">
			<select class="infohtml" id="chip">
				<option value="PCF8574">PCF8574</option>
				<option value="MCP23008">MCP23008</option>
				<option value="MCP23017">MCP23017</option>
			</select>
			<select class="infohtml" id="address">
				<option value="0x27">0x27</option>
			</select>
		</div>
	</div>
*/ } );
$( '#setting-lcdchar' ).click( function() {
	info( {
		  icon        : 'gear'
		, title       : 'Character LCD'
		, content     : infolcdchar
		, boxwidth    : 130
		, nofocus     : 1
		, preshow     : function() {
			var settings = G.lcdcharset.split( ' ' );
			G.cols = settings[ 0 ];
			G.charmap = settings[ 1 ];
			$( '#charmap option[value='+ G.charmap +']' ).prop( 'selected', 1 );
			if (  settings.length > 2 ) {
				G.inf = 'i2c';
				G.i2caddress = settings[ 2 ];
				G.i2cchip = settings[ 3 ];
				$( '#chip option[value='+ G.i2cchip +']' ).prop( 'selected', 1 );
			} else {
				G.inf = 'gpio';
			}
			$( '#cols input[value='+ G.cols +']' ).prop( 'checked', 1 )
			$( '#inf input[value='+ G.inf +']' ).prop( 'checked', 1 )
			$( '#divi2c' ).toggleClass( 'hide', G.inf === 'gpio' );
			$( '#inf' ).change( function() {
				$( '#divi2c' ).toggleClass( 'hide', G.inf === 'gpio' );
			} );
			if ( G.lcdcharaddr ) {
				var addr = G.lcdcharaddr.split( ' ' );
				var opt = '';
				addr.forEach( function( el ) {
					opt += '<option value="0x'+ el +'">0x'+ el +'</option>';
				} );
				$( '#address' ).html( opt );
				$( '#address option[value='+ G.i2caddress +']' ).prop( 'selected', 1 );
			}
			if ( $( '#address option' ).length === 1 ) $( '#address' ).prop( 'disabled', 1 );
			$( '.extrabtn' ).toggleClass( 'hide', !G.lcdchar );
		}
		, cancel      : function() {
			if ( !G.lcdchar ) $( '#lcdchar' ).prop( 'checked', 0 );
		}
		, buttonlabel : [ 'Splash', 'Off' ]
		, buttoncolor : [ '#448822',       '#de810e' ]
		, button      : [ 
			  function() { bash( '/srv/http/bash/lcdchar.py rr' ) }
			, function() { bash( '/srv/http/bash/lcdchar.py off' ) }
		]
		, ok          : function() {
			var cols = $( '#cols input:checked' ).val();
			var charmap = $( '#charmap').val();
			var changed = !G.lcdchar || cols !== G.cols || charmap !== G.charmap;
			var inf = $( '#inf input:checked' ).val();
			if ( inf === 'i2c' ) {
				var chip = $( '#chip').val();
				var address = $( '#address').val();
				changed = changed || inf !== G.inf || chip !== G.i2cchip || address !== G.i2caddress;
			}
			if ( changed ) {
				rebootText( 'Enable', 'Character LCD' );
				var cmd = [ 'lcdcharset', cols, charmap ];
				if ( inf === 'i2c' ) cmd.push( chip, address );
				cmd.push( G.reboot.join( '\n' ) );
				bash( cmd );
				notify( 'Character LCD', 'Change ...', 'gear' );
			}
		}
	} );
} );
$( '#lcd' ).click( function() {
	G.lcd = $( this ).prop( 'checked' );
	rebootText( G.lcd ? 'Enable' : G.lcd, 'TFT LCD' );
	notify( 'TFT LCD', G.lcd, 'gear' );
	bash( [ 'lcd', G.lcd, G.reboot.join( '\n' ) ] );
} );
$( '#setting-lcd' ).click( function() {
	info( {
		  icon        : 'edit'
		, title       : 'TFT LCD'
		, message     : 'Calibrate touchscreen?'
						+'<br>(Get stylus ready.)'
		, oklabel     : 'Start'
		, ok          : function() {
			notify( 'Calibrate Touchscreen', 'Start ...', 'edit' );
			bash( [ 'lcdcalibrate' ] );
		}
	} );
} );
$( '#relays' ).click( function() {
	G.relays = $( this ).prop( 'checked' );
	$( '#setting-relays' ).toggleClass( 'hide', !G.relays );
	notify( 'GPIO Relay', G.relays, 'gpio blink' );
	bash( [ 'relays', G.relays ] );
} );
$( '#setting-relays' ).click( function() {
	location.href = '/settings/relays.php';
} );
$( '#hostname' ).click( function() {
	info( {
		  icon      : 'plus-r'
		, title     : 'Player Name'
		, textlabel : 'Name'
		, textvalue : G.hostname
		, ok        : function() {
			var hostname = $( '#infoTextBox' ).val().replace( /[^a-zA-Z0-9-]+/g, '-' ).replace( /(^-*|-*$)/g, '' );
			if ( hostname !== G.hostname ) {
				G.hostname = hostname;
				$( '#hostname' ).val( hostname );
				notify( 'Name', 'Change ...', 'sliders' );
				bash( [ 'hostname', hostname ] );
			}
		}
	} );
} );
$( '#setting-regional' ).click( function() {
	info( {
		  icon      : 'gear'
		, title     : 'Regional Settings'
		, textlabel : [ 'NTP server', 'Regulatory domain' ]
		, textvalue : [ G.ntp, G.regdom || '00' ]
		, footer    : '<px70/><px60/>00 - common for all regions'
		, ok        : function() {
			var ntp = $( '#infoTextBox' ).val();
			var regdom = $( '#infoTextBox1' ).val();
			if ( ntp !== G.ntp || regdom !== G.regdom ) {
				G.ntp = ntp;
				G.regdom = regdom;
				notify( 'Regional Settings', 'Change ...', 'gear' );
				bash( [ 'regional', ntp, regdom ] );
			}
		}
	} );
} );
$( '#timezone' ).on( 'selectric-change', function( e ) {
	G.timezone = $( this ).val();
	bash( [ 'timezone', G.timezone ] );
} );
$( '#soundprofile' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( checked ) {
		$( '#setting-soundprofile' ).click();
	} else {
		notify( "Kernel Sound Profile", 'Disable ...', 'volume' );
		bash( [ 'soundprofiledisable' ] );
	}
} );
$( '#setting-soundprofile' ).click( function() {
	var defaultval = '1500 1000 60 18000000';
	if ( !G.soundprofile ) G.soundprofile = defaultval;
	var existing = G.soundprofile.split( ' ' );
	if ( G.rpi01 ) {
		var lat = [ 1500000, 850000, 500000, 120000, 500000, 1500000, 145655, 6000000 ];
	} else {
		var lat = [ 4500000, 3500075, 1000000, 2000000, 3700000, 1500000, 145655, 6000000 ];
	}
	var radio = {
		  _Default  : defaultval
		, RuneAudio : '1500 1000 0 '+ lat[ 0 ]
		, _ACX      : '1500 4000 0 '+ lat[ 1 ]
		, Orion     : '1000 4000 20 '+ lat[ 2 ]
		, _OrionV2  : '1000 4000 0 '+ lat[ 3 ]
		, OrionV3   : '1000 4000 0 '+ lat[ 5 ]
		, _OrionV4  : '1000 4000 60 '+ lat[ 6 ]
		, Um3ggh1U  : '1500 1000 0 '+ lat[ 4 ]
		, _Custom   : 0
	}
	var values = Object.values( radio );
	info( {
		  icon    : 'volume'
		, title   : 'Kernel Sound Profile'
		, textlabel : [ 'eth0 mtu <gr>(byte)</gr>', 'eth0 txqueuelen', 'vm.swappiness', 'kernel.sched_latency_ns <gr>(ns)</gr>' ]
		, textvalue : existing
		, boxwidth  : 110
		, radio   : radio
		, checked : values.indexOf( G.soundprofile ) !== -1 ? G.soundprofile : 0
		, preshow : function() {
			$( '#infoRadio input' ).last().prop( 'disabled', 1 );
			$( '#infoRadio' ).change( function() {
				var val = $( '#infoRadio input:checked' ).val().split( ' ' );
				for ( i = 0; i < 4; i++ ) $( '#infoTextBox'+ ( i !== 0 ? i : '' ) ).val( val[ i ] );
			} );
			$( '.infoinput' ).on( 'keyup', function() {
				if (  $( this ).val() !== existing[ $( '.infoinput' ).index() ] ) {
					$( '#infoRadio input' ).last().prop( 'checked', 1 );
				} else {
					$( '#infoRadio input[value="'+ G.soundprofile +'"]' ).prop( 'checked', 1 );
				}
			} );
		}
		, cancel  : function() {
			if ( G.soundprofile === defaultval ) $( '#soundprofile' ).prop( 'checked', 0 );
		}
		, ok      : function() {
			var soundprofile = $( '#infoTextBox' ).val();
			for ( i = 1; i < 4; i++ ) soundprofile += ' '+ $( '#infoTextBox'+ i ).val();
			if ( soundprofile === G.soundprofile ) return
				
			if ( soundprofile === defaultval ) {
				bash( [ 'soundprofiledisable' ] );
			} else {
				bash( [ 'soundprofileset', soundprofile ] );
			}
		}
	} );
} );
$( '#backuprestore' ).click( function( e ) {
	if ( $( e.target ).hasClass( 'help' ) ) return
	
	var icon = 'sd';
	var restoretitle = 'Restore Settings';
	var backuptitle = restoretitle.replace( 'Restore', 'Backup' );
	var maintitle = 'Backup/'+ restoretitle;
	info( {
		  icon        : icon
		, title       : maintitle
		, message     :  '<span style="display: inline-block; text-align: left"">'
						    +'&bull; Settings'
						+'<br>&bull; Library database'
						+'<br>&bull; Saved playlists'
						+'<br>&bull; Bookmarks'
						+'<br>&bull; Lyrics'
						+'<br>&bull; WebRadios'
						+'</span>'
		, buttonwidth : 1
		, buttonlabel : 'Backup'
		, buttoncolor : '#0a8c68'
		, button      : function() {
			notify( backuptitle, 'Backup ...', 'sd blink', -1 );
			bash( [ 'databackup' ], function( data ) {
				if ( data == 1 ) {
					notify( backuptitle, 'Download ...', 'sd blink' );
					fetch( '/data/tmp/backup.gz' )
						.then( response => response.blob() )
						.then( blob => {
							var url = window.URL.createObjectURL( blob );
							var a = document.createElement( 'a' );
							a.style.display = 'none';
							a.href = url;
							a.download = 'backup.gz';
							document.body.appendChild( a );
							a.click();
							setTimeout( () => {
								a.remove();
								window.URL.revokeObjectURL( url );
								bannerHide();
							}, 1000 );
						} ).catch( () => {
							info( {
								  icon    : icon
								, title   : backuptitle
								, message : '<wh>Warning!</wh><br>File download failed.'
							} );
							bannerHide();
						} );
				} else {
					info( {
						  icon    : icon
						, title   : backuptitle
						, message : 'Backup failed.'
					} );
					bannerHide();
				}
			} );
		}
		, oklabel     : 'Restore'
		, ok          : function() {
			info( {
				  icon        : icon
				, title       : restoretitle
				, message     : 'Restore from:'
				, radio       : {
					  'Backup file <code>*.gz</code>' : 'restore'
					, 'Reset to default'              : 'reset'
				}
				, checked     : 'restore'
				, fileoklabel : 'Restore'
				, filetype    : '.gz'
				, filefilter  : 1
				, preshow     : function() {
					$( '#infoRadio input' ).click( function() {
						if ( $( '#infoRadio input:checked' ).val() !== 'restore' ) {
							$( '#infoFilename' ).empty()
							$( '#infoFileBox' ).val( '' );
							$( '#infoFileLabel' ).addClass( 'hide infobtn-primary' );
							$( '#infoOk' ).removeClass( 'hide' );
						} else {
							$( '#infoOk' ).addClass( 'hide' );
							$( '#infoFileLabel' ).removeClass( 'hide' );
						}
					} );
				}
				, ok          : function() {
					notify( restoretitle, 'Restore ...', 'sd blink', -1 );
					var checked = $( '#infoRadio input:checked' ).val();
					if ( checked === 'reset' ) {
						bash( '/srv/http/bash/datareset.sh', bannerHide );
					} else {
						var file = $( '#infoFileBox' )[ 0 ].files[ 0 ];
						var formData = new FormData();
						formData.append( 'cmd', 'datarestore' );
						formData.append( 'file', file );
						$.ajax( {
							  url         : cmdphp
							, type        : 'POST'
							, data        : formData
							, processData : false  // no - process the data
							, contentType : false  // no - contentType
							, success     : function( data ) {
								if ( data ) {
									if ( data !== 'restored' ) G.reboot = data.split( '\n' );
								} else {
									info( {
										  icon    : icon
										, title   : restoretitle
										, message : 'File upload failed.'
									} );
									bannerHide();
									$( '#loader' ).addClass( 'hide' );
								}
							}
						} );
					}
					setTimeout( function() {
						$( '#loader' ).removeClass( 'hide' );
					}, 0 );
				}
			} );
		}
	} );
} );

} ); // document ready end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
