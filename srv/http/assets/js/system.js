$( function() { // document ready start >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

function getStatus( service ) {
	var $code = $( '#code'+ service );
	if ( service === 'mpdscribble' ) service += '@mpd';
	bash( 'systemctl status '+ service, function( status ) {
		if ( service === 'spotifyd' ) status = status.replace( /.*Authenticated as.*\n|.*Country:.*\n/g, '' );
		$code
			.html( statusColor( status ) )
			.removeClass( 'hide' );
	} );
}
function getStatusRefresh( service ) {
	service !== 'localbrowser' ? resetLocal() : resetLocal( 7000 );
	if ( !$( '#code'+ service ).hasClass( 'hide' ) ) getStatus( service );
}
function getIwregget() {
	bash( 'iw reg get', function( status ) {
		$( '#codeiwregget' )
			.html( status )
			.removeClass( 'hide' );
	} );
}
function getJournalctl() {
	if ( $( '#codejournalctl' ).text() ) {
		$( '#codejournalctl' ).removeClass( 'hide' );
	} else {
		bash( [ 'statusbootlog' ], function( data ) {
			$( '#codejournalctl' )
				.html( data )
				.removeClass( 'hide' );
			$( '#journalctlicon' )
				.removeClass( 'fa-refresh blink' )
				.addClass( 'fa-code' );
		} );
		$( '#journalctlicon' )
			.removeClass( 'fa-code' )
			.addClass( 'fa-refresh blink' );
	}
}
function getConfigtxt() {
	bash( 'cat /boot/config.txt', function( status ) {
		setTimeout( function() {
		$( '#codeconfigtxt' )
			.html( status )
			.removeClass( 'hide' );
		}, 1000 );
	} );
}
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
		undervoltage = '<br><red>'+ warning +' Voltage under 4.7V</red>';
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
function soundProfile( arg, callback ) {
	var cmd = [ 'cmd-soundprofile.sh' ];
	if ( arg ) cmd = cmd.concat( arg );
	$.post( 'cmd.php', { cmd: 'sh', sh: cmd }, function( data ) {
		G.soundprofilecus = data;
		resetLocal();
	} );
}

refreshData = function() { // system page: use resetLocal() to aviod delay
	bash( '/srv/http/bash/system-data.sh', function( list ) {
		G = list;
		G.reboot = list.reboot ? list.reboot.split( '\n' ) : [];
		G.sources.pop(); // remove 'reboot' from sources-data.sh
		var systemlabel =
			 'RuneAudio<br>'
			+'Hardware<br>'
			+'SoC<br>'
			+'Output Device<br>'
			+'Kernel<br>'
			+'<span class="settings" data-setting="mpd">MPD<i class="fa fa-gear"></i></span><br>'
			+'<span class="settings" data-setting="network">Network<i class="fa fa-gear"></i></span>';
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
		if ( G.sources.length ) {
			systemlabel += '<span id="sources" class="settings">Sources<i class="fa fa-gear"></i></span>';
			var sourcelist = '';
			$.each( G.sources, function( i, val ) {
				sourcelist += '<i class="fa fa-'+ val.icon +' gr"></i>&ensp;'+ val.mountpoint.replace( '/mnt/MPD/USB/', '' );
				sourcelist += ( val.size ? bullet + val.size : '' ) +'<br>';
				systemlabel += '<br>';
			} );
		}
		$( '#systemlabel' ).html( systemlabel );
		var mpdstats = '';
		if ( G.mpdstats ) {
		var counts = G.mpdstats.split( ' ' );
		var mpdstats = '<span class="wide">&emsp;<i class="fa fa-music gr"></i>&nbsp;'+ Number( counts[ 0 ] ).toLocaleString()
					  +'&ensp;<i class="fa fa-album gr"></i>&ensp;'+ Number( counts[ 1 ] ).toLocaleString()
					  +'&ensp;<i class="fa fa-artist gr"></i> '+ Number( counts[ 2 ] ).toLocaleString() +'</span>';
		}
		$( '#system' ).html(
			  '<i class="fa fa-addons gr" style="line-height: 20px;"></i> '+ G.version +' <gr>'+ G.versionui +'</gr>'+ bullet + G.hostname +'<br>'
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
		$( '#airplay' ).prop( 'checked', G.airplay );
		$( '#spotify' ).prop( 'checked', G.spotify );
		$( '#setting-spotify' ).toggleClass( 'hide', !G.spotify );
		$( '#upnp' ).prop( 'checked', G.upnp );
//		$( '#setting-upnp' ).toggleClass( 'hide', !G.upnp );
		$( '#localbrowser' ).prop( 'checked', G.localbrowser );
		$( '#setting-localbrowser' ).toggleClass( 'hide', !G.localbrowser );
		$( '#samba' ).prop( 'checked', G.samba );
		$( '#setting-samba' ).toggleClass( 'hide', !G.samba );
		$( '#snapcast' ).prop( 'checked', G.snapcast );
		if ( G.snapcast ) {
			$( '#divsnapclient' ).addClass( 'hide' );
		} else {
			$( '#divsnapclient' ).removeClass( 'hide' );
			$( '#snapclient' )
				.prop( 'checked', G.snapclient )
				.data( 'latency', G.snaplatency );
			$( '#setting-snapclient' ).toggleClass( 'hide', !G.snapclient );
		}
		$( '#streaming' ).prop( 'checked', G.streaming );
		$( '#ip' ).text( G.streamingip +':8000' );
		$( '#gpio' ).prop( 'checked', G.gpio );
		$( '#mpdscribble' ).prop( 'checked', G.mpdscribble );
		$( '#setting-mpdscribble' ).toggleClass( 'hide', !G.mpdscribble );
		$( '#login' ).prop( 'checked', G.login );
		$( '#setting-login' ).toggleClass( 'hide', !G.login );
		$( '#avahi' ).prop( 'checked', G.avahi );
		$( '#avahiname' ).text( G.hostname.toLowerCase() );
		$( '#autoplay' ).prop( 'checked', G.autoplay );
		$( '#i2smodule' ).val( 'none' );
		$( '#i2smodule option' ).filter( function() {
			var $this = $( this );
			return $this.text() === G.audiooutput && $this.val() === G.audioaplayname;
		} ).prop( 'selected', true );
		$( '#i2smodule' ).selectric( 'refresh' );
		var i2senabled = $( '#i2smodule' ).val() === 'none' ? false : true;
		$( '#divi2smodulesw' ).toggleClass( 'hide', i2senabled );
		$( '#divi2smodule' ).toggleClass( 'hide', !i2senabled );
		$( '#soundprofile' ).prop( 'checked', G.soundprofile !== '' );
		$( '#setting-soundprofile' ).toggleClass( 'hide', G.soundprofile === '' );
		$( '#eth0help' ).toggleClass( 'hide', G.ip.slice( 0, 4 ) !== 'eth0' );
		$( '#onboardaudio' ).prop( 'checked', G.onboardaudio );
		$( '#divonboardaudio' ).toggleClass( 'hide', !i2senabled );
		$( '#bluetooth' ).prop( 'checked', G.bluetooth );
		$( '#wlan' ).prop( 'checked', G.wlan );
		$( '#hostname' ).val( G.hostname );
		$( '#timezone' )
			.val( G.timezone )
			.selectric( 'refresh' );
		if ( !$( '#codejournalctl' ).hasClass( 'hide' ) ) getJournalctl();
		if ( !$( '#codeconfigtxt' ).hasClass( 'hide' ) ) getConfigtxt();
		resetLocal();
		showContent();
	}, 'json' );
}
refreshData();
//---------------------------------------------------------------------------------------
$( '#timezone, #i2smodule' ).selectric( { maxHeight: 400 } );
$( '.selectric-input' ).prop( 'readonly', 1 ); // fix - suppress screen keyboard

$( '.container' ).on( 'click', '.settings', function() {
	location.href = 'index-settings.php?p='+ $( this ).data( 'setting' );
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
		notify( 'System Status', 'Refresh every 10 seconds.<br>Click again to stop.', 'sliders', 10000 );
	}
} );
$( '#airplay' ).click( function( e ) {
	G.airplay = $( this ).prop( 'checked' );
	notify( 'AirPlay Renderer', G.airplay, 'airplay' );
	bash( [ 'airplay', G.airplay ], getStatusRefresh( 'shairport-sync' ) );
} );
$( '#snapclient' ).click( function( e ) {
	G.snapclient = $( this ).prop( 'checked' );
	$( '#setting-snapclient' ).toggleClass( 'hide', !G.snapclient );
	notify( 'SnapClient Renderer', G.snapclient, 'snapcast' );
	bash( [ 'snapclient', G.snapclient ], getStatusRefresh( 'snapclient' ) );
} );
$( '#setting-snapclient' ).click( function() {
	info( {
		  icon          : 'snapcast'
		, title         : 'SnapClient'
		, message       : 'Sync client to server:'
		, textlabel     : 'Latency <gr>(ms)</gr>'
		, textvalue     : G.snaplatency
		, passwordlabel : 'Password'
		, footer        : '<px60/>*Snapserver - if not <wh>rune</wh>'
		, ok            : function() {
			var latency = Math.abs( $( '#infoTextBox' ).val() );
			if ( latency !== G.snaplatency ) {
				G.snaplatency = latency;
				G.snapserverpw = $( '#infoPasswordBox' ).val();
				notify( 'Snapclient', 'Change ...', 'snapcast' );
				bash( [ 'snapclientset', G.snaplatency, G.snapserverpw ], resetLocal );
			}
		}
	} );
} );
$( '#spotify' ).click( function() {
	G.spotify = $( this ).prop( 'checked' );
	$( '#setting-spotify' ).toggleClass( 'hide', !G.spotify );
	notify( 'Spotify Connect', G.spotify, 'spotify' );
	bash( [ 'spotify', G.spotify ], getStatusRefresh( 'spotifyd' ) );
} );
$( '#setting-spotify' ).click( function() {
	$.post( cmdphp, {
		  cmd  : 'exec'
		, exec : "aplay -L | grep -v '^\\s\\|^null'"
	}, function( devices ) {
		var select = {}
		devices.forEach( function( val ) {
			select[ val ] = val;
		} );
		info( {
			  icon        : 'spotify'
			, title       : 'Spotify Renderer'
			, message     : 'Manually select audio output:'
						   +'<br>(Only if current one not working)'
			, selectlabel : 'Device'
			, select      : select
			, checked     : G.spotifydevice
			, preshow : function() {
				$( '#infoSelectBox' )
				$( '#infoOk' ).addClass( 'disabled' );
				$( '#infoSelectBox' )
					.selectric()
					.on( 'selectric-change', function() {
						$( '#infoOk' ).toggleClass( 'disabled', $( this ).val() === G.spotifydevice );
					} );
			}
			, ok          : function() {
				var device = $( '#infoSelectBox option:selected' ).text();
				if ( device !== G.spotifydevice ) {
					G.spotifydevice = device;
					notify( 'Spotify Renderer', 'Change ...', 'spotify' );
					bash( [ 'spotifyset', device ], resetLocal );
				}
			}
		} );
	}, 'json' );
} );
$( '#upnp' ).click( function( e ) {
	G.upnp = $( this ).prop( 'checked' );
	notify( 'UPnP Renderer', G.upnp, 'upnp fa-s' );
	bash( [ 'upnp', G.upnp ], getStatusRefresh( 'upmpdcli' ) );
} );
$( '#snapcast' ).click( function( e ) {
	G.snapcast = $( this ).prop( 'checked' );
	if ( G.snapcast ) {
		if ( G.snapclient ) $( '#snapclient' ).click();
		$( '#divsnapclient' ).addClass( 'hide' );
	} else {
		$( '#divsnapclient' ).removeClass( 'hide' );
	}
	notify( 'Snapcast - Sync Streaming Server', G.snapcast, 'snapcast' );
	bash( [ 'snapcast', G.snapcast ], getStatusRefresh( 'snapserver' ) );
} );
$( '#streaming' ).click( function( e ) {
	G.streaming = $( this ).prop( 'checked' );
	notify( 'HTTP Streaming', G.streaming, 'mpd' );
	bash( [ 'streaming', G.streaming ], resetLocal );
} );
$( '#localbrowser' ).click( function( e ) {
	G.localbrowser = $( this ).prop( 'checked' );
	$( '#setting-localbrowser' ).toggleClass( 'hide', !G.localbrowser );
	notify( 'Chromium - Browser on RPi', G.localbrowser, 'chromium blink' );
	bash( [ 'localbrowser', G.localbrowser ], getStatusRefresh( 'localbrowser' ) );
} );
var localbrowserinfo = heredoc( function() { /*
	<div id="infoText" class="infocontent">
		<div id="infotextlabel">
			<a class="infolabel">
				Screen off <gr>(min)</gr><br>
				Zoom <gr>(0.5-2.0)</gr>
			</a>
		</div>
		<div id="infotextbox">
			<input type="text" class="infoinput input" id="infoTextBox" spellcheck="false" style="width: 60px; text-align: center">
			<input type="text" class="infoinput input" id="infoTextBox1" spellcheck="false" style="width: 60px; text-align: center">
		</div>
	</div>
	<hr>
	Screen rotation<br>
	<div id="infoRadio" class="infocontent infohtml" style="text-align: center">
		&ensp;0°<br>
		<label><input type="radio" name="inforadio" value="NORMAL"></label><br>
		&nbsp;<label>90°&ensp;<i class="fa fa-undo"></i>&ensp;<input type="radio" name="inforadio" value="CCW"></label><px30/>
		<label><input type="radio" name="inforadio" value="CW"> <i class="fa fa-redo"></i>&ensp;90°&nbsp;</label><br>
		<label><input type="radio" name="inforadio" value="UD"></label><br>
		&nbsp;180°
	</div>
	<hr>
	<div id="infoCheckBox" class="infocontent infohtml">
		<label><input type="checkbox">&ensp;Mouse pointer</label><br>
	</div>
*/ } );
$( '#setting-localbrowser' ).click( function( e ) {
	info( {
		  icon        : 'chromium'
		, title       : 'Browser on RPi'
		, content     : localbrowserinfo
		, preshow     : function() {
			$( '#infoTextBox1' ).val( G.zoom );
			$( '#infoTextBox' ).val( G.screenoff );
			$( 'input[name=inforadio]' ).val( [ G.rotate ] );
			$( '#infoCheckBox input:eq( 0 )' ).prop( 'checked', G.cursor );
		}
		, buttonlabel : '<i class="fa fa-refresh"></i>Refresh'
		, buttoncolor : '#de810e'
		, button      : function() {
			bash( 'curl -s -X POST http://127.0.0.1/pub?id=reload -d 1' );
		}
		, buttonwidth : 1
		, ok          : function() {
			var cursor    = $( '#infoCheckBox input:eq( 0 )' ).prop( 'checked' );
			var rotate    = $( 'input[name=inforadio]:checked' ).val();
			var screenoff = $( '#infoTextBox' ).val();
			var zoom = parseFloat( $( '#infoTextBox1' ).val() ) || 1;
			G.zoom      = zoom < 2 ? ( zoom < 0.5 ? 0.5 : zoom ) : 2;
			if ( cursor === G.cursor && rotate === G.rotate 
				&& screenoff === G.screenoff && zoom === G.zoom ) return
			
			G.cursor    = cursor;
			G.rotate    = rotate;
			G.screenoff = screenoff;
			G.zoom      = zoom;
			notify( 'Chromium - Browser on RPi', 'Change ...', 'chromium blink' );
			bash( [ 'localbrowserset', rotate, cursor, ( screenoff * 60 ), zoom ], function() {
				resetLocal( 7000 );
			} );
		}
	} );
} );
$( '#samba' ).click( function( e ) {
	G.samba = $( this ).prop( 'checked' );
	$( '#setting-samba' ).toggleClass( 'hide', !G.samba );
	notify( 'Samba - File Sharing', G.samba, 'network blink' );
	bash( [ 'samba', G.samba ], getStatusRefresh( 'smb' ) );
} );
$( '#setting-samba' ).click( function() {
	info( {
		  icon     : 'network'
		, title    : 'Samba File Sharing'
		, message  : '<wh>Write</wh> permission:</gr>'
		, checkbox : { '<gr>/mnt/MPD/</gr>SD': 1, '<gr>/mnt/MPD/</gr>USB': 1 }
		, preshow  : function() {
			$( '#infoCheckBox input:eq( 0 )' ).prop( 'checked', G.writesd );
			$( '#infoCheckBox input:eq( 1 )' ).prop( 'checked', G.writeusb );
		}
		, ok       : function() {
			var writesd = $( '#infoCheckBox input:eq( 0 )' ).prop( 'checked' );
			var writeusb = $( '#infoCheckBox input:eq( 1 )' ).prop( 'checked' );
			if ( writesd !== G.writesd || writeusb !== G.writeusb ) {
				G.writesd = writesd;
				G.writeusb = writeusb;
				notify( 'Samba - File Sharing', 'Change ...', 'network blink' );
				bash( [ 'sambaset', G.writesd, G.writeusb ], resetLocal );
			}
		}
	} );
} );
$( '#gpio' ).click( function() {
	G.gpio = $( this ).prop( 'checked' );
	$( '#setting-gpio' ).toggleClass( 'hide', !G.gpio );
	notify( 'GPIO Relay', G.gpio, 'gpio blink' );
	bash( [ 'gpio', G.gpio ], resetLocal );
} );
$( '#mpdscribble' ).click( function() {
	var mpdscribble = $( this ).prop( 'checked' );
	if ( mpdscribble && !G.mpdscribbleuser ) {
		$( '#setting-mpdscribble' ).click();
	} else {
		notify( 'Scrobbler', mpdscribble, 'lastfm' );
		bash( [ 'mpdscribble', mpdscribble ], function( std ) {
			G.mpdscribble = std != -1 ? true : false;
			$( '#setting-mpdscribble' ).toggleClass( 'hide', !G.mpdscribble );
			getStatusRefresh( 'mpdscribble' );
		} );
	}
} );
$( '#setting-mpdscribble' ).click( function() {
	info( {
		  icon          : 'lastfm'
		, title         : 'Scrobbler'
		, textlabel     : 'Username'
		, textvalue     : G.mpdscribbleuser
		, passwordlabel : 'Password'
		, cancel        : function() {
			$( '#mpdscribble' ).prop( 'checked', G.mpdscribble );
		}
		, ok            : function() {
			G.mpdscribbleuser = $( '#infoTextBox' ).val().replace( /(["&()\\])/g, '\$1' );
			var password = $( '#infoPasswordBox' ).val().replace( /(["&()\\])/g, '\$1' );
			notify( 'Scrobbler', G.mpdscribble ? 'Change ...' : 'Enable ...', 'lastfm' );
			bash( [ 'mpdscribbleset', G.mpdscribbleuser, password ], function( std ) {
				G.mpdscribble = std != -1 ? true : false;
				$( '#setting-mpdscribble' ).toggleClass( 'hide', !G.mpdscribble );
				resetLocal();
		} );
		}
	} );
} );
$( '#login' ).click( function( e ) {
	G.login = $( this ).prop( 'checked' );
	$( '#setting-login' ).toggleClass( 'hide', !G.login );
	notify( 'Password Login', G.login, 'lock' );
	bash( [ 'login', G.login ], resetLocal );
	if ( G.login && G.passworddefault ) {
		info( {
			  icon    : 'lock'
			, title   : 'Password'
			, message : 'Default password is <wh>rune</wh>'
		} );
	}
} );
$( '#setting-login' ).click( function() {
	info( {
		  icon          : 'lock'
		, title         : 'Change Password'
		, passwordlabel : [ 'Existing', 'New' ]
		, ok            : function() {
			$.post( cmdphp, {
				  cmd      : 'login'
				, password : $( '#infoPasswordBox' ).val()
				, pwdnew   : $( '#infoPasswordBox1' ).val()
			}, function( std ) {
				info( {
					  icon    : 'lock'
					, title   : 'Change Password'
					, nox     : 1
					, message : ( std ? 'Password changed' : 'Wrong existing password' )
				} );
			} );
		}
	} );
} );
$( '#autoplay' ).click( function() {
	G.autoplay = $( this ).prop( 'checked' );
	notify( 'Play on Startup', G.autoplay, 'refresh-play' );
	bash( [ 'autoplay', G.autoplay ], resetLocal );
} );
$( '#onboardaudio' ).click( function( e ) {
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
		bash( [ 'onboardaudio', G.onboardaudio, G.reboot.join( '\n' ) ], resetLocal );
	}
} );
$( '#bluetooth' ).click( function( e ) {
	G.bluetooth = $( this ).prop( 'checked' );
	rebootText( G.bluetooth ? 'Enable' : 'Disable', 'on-board Bluetooth' );
	notify( 'On-board Bluetooth', G.bluetooth, 'bluetooth' );
	bash( [ 'bluetooth', G.bluetooth, G.reboot.join( '\n' ) ], resetLocal );
} );
$( '#wlan' ).click( function( e ) {
	G.wlan = $( this ).prop( 'checked' );
	notify( 'On-board Wi-Fi', G.wlan, 'wifi-3' );
	bash( [ 'wlan', G.wlan ], resetLocal );
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
$( '#i2smodule' ).on( 'selectric-change', function( e ) {
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
		rebootText( 'Enable', 'I&#178;S Module' );
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
		rebootText( 'Disable', 'I&#178;S Module' );
		notify( 'I&#178;S Module', 'Disable ...', 'volume' );
	}
	bash( [ 'i2smodule', G.audioaplayname, G.audiooutput, G.reboot.join( '\n' ) ], function() {
			resetLocal();
			getConfigtxt();
		} );
	$( '#output' ).text( G.audiooutput );
} );
$( '#soundprofile' ).click( function( e ) {
	var checked = $( this ).prop( 'checked' );
	rebootText( checked ? 'Enable' : 'Disable', 'sound profile' );
	notify( 'Sound Profile', checked, 'volume' );
	soundProfile( '', function( data ) {
		G.soundprofilecus = data;
		resetLocal();
	} );
	$( '#setting-soundprofile' ).toggleClass( 'hide', !checked );
	G.soundprofile = checked ? 'RuneAudio' : '';
} );
$( '#infoOverlay' ).on( 'click', '#custom', function() {
	var val = G.soundprofilecus || G.soundprofileval;
	info( {
		  icon      : 'volume'
		, title     : 'Sound Profile'
		, message   : 'Custom value (Current value shown)'
		, textlabel : [ 'eth0 mtu (byte)', 'eth0 txqueuelen', 'vm.swappiness (0-100)', 'kernel.sched_latency_ns (ns)' ]
		, textvalue : val.split( ' ' )
		, boxwidth  : 110
		, preshow   : function() {
			if ( G.ip.slice( 0, 4 ) !== 'eth0' ) $( '#infoTextBox, #infoTextBox1' ).hide();
		}
		, ok        : function() {
			var soundprofileval = $( '#infoTextBox' ).val() || 0;
			for ( i = 1; i < 4; i++ ) {
				soundprofileval += ' '+ ( $( '#infoTextBox'+ i ).val() || 0 );
			}
			if ( soundprofileval != G.soundprofileval ) {
				G.soundprofileval = soundprofileval;
				G.soundprofile = 'custom';
				notify( 'Sound Profile', 'Change ...', 'volume' );
				soundProfile( [ 'custom', soundprofileval ], resetLocal );
			}
		}
	} );
} );
$( '#setting-soundprofile' ).click( function() {
	var radio= {
		  RuneAudio : 'RuneAudio'
		, ACX       : 'ACX'
		, Orion     : 'Orion'
		, 'Orion V2': 'OrionV2'
		, Um3ggh1U  : 'Um3ggh1U'
	}
	if ( G.audioaplayname === 'snd_rpi_iqaudio_dac' ) radio[ 'IQaudio Pi-DAC' ] = 'OrionV3';
	if ( G.audiooutput === 'BerryNOS' ) radio[ 'BerryNOS' ] = 'OrionV4';
	radio[ 'Custom&ensp;<i id="custom" class="fa fa-gear"></i>' ] = 'custom';
	info( {
		  icon    : 'volume'
		, title   : 'Sound Profile'
		, radio   : radio
		, checked : G.soundprofile
		, cancel  : function() {
			if ( !G.soundprofile ) {
				$( '#soundprofile' ).prop( 'checked', 0 );
				$( '#setting-soundprofile' ).addClass( 'hide' );
			}
		}
		, preshow : function() {
			$( '#infoRadio input[value=custom]' ).click( function( e ) {
				if ( !G.soundprofilecus ) {
					$( '#infoOverlay #custom' ).click();
					return
				}
			} );
		}
		, ok      : function() {
			var soundprofile = $( 'input[name=inforadio]:checked' ).val();
			if ( soundprofile !== G.soundprofile ) {
				rebootText( G.soundprofile ? 'Change' : 'Enable', 'sound profile' );
				G.soundprofile = soundprofile;
				notify( 'Sound Profile', 'Change ...', 'volume' );
				soundProfile( [ soundprofile ], function( data ) {
					G.soundprofileval = data;
					resetLocal();
				} );
			}
		}
	} );
} );
$( '#hostname' ).click( function() {
	info( {
		  icon      : 'rune'
		, title     : 'Player Name'
		, textlabel : 'Name'
		, textvalue : G.hostname
		, ok        : function() {
			var hostname = $( '#infoTextBox' ).val().replace( /[^a-zA-Z0-9-]+/g, '-' ).replace( /(^-*|-*$)/g, '' );
			if ( hostname !== G.hostname ) {
				G.hostname = hostname;
				$( '#hostname' ).val( hostname );
				notify( 'Name', 'Change ...', 'sliders' );
				bash( [ 'hostname', hostname ], resetLocal );
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
				bash( [ 'regional', ntp, regdom ], resetLocal );
			}
		}
	} );
} );
$( '#timezone' ).on( 'selectric-change', function( e ) {
	G.timezone = $( this ).val();
	bash( [ 'timezone', G.timezone ] );
} );
$( '.status' ).click( function() {
	$this = $( this );
	var service = $this.data( 'service' );
	$code = $( '#code'+ service );
	if ( $code.hasClass( 'hide' ) ) {
		getStatus( service );
	} else {
		$code.addClass( 'hide' );
	}
} );
$( '#journalctl' ).click( function( e ) {
	codeToggle( e.target, this.id, getJournalctl );
} );
$( '#configtxt' ).click( function( e ) {
	codeToggle( e.target, this.id, getConfigtxt );
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
			bash( '/srv/http/bash/cmd.sh databackup', function( data ) {
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
