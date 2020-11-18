$( function() { // document ready start >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

refreshData = function() { // system page: use resetLocal() to aviod delay
	bash( '/srv/http/bash/features-data.sh', function( list ) {
		G = list;
		G.reboot = list.reboot ? list.reboot.split( '\n' ) : [];
		$( '#airplay' ).prop( 'checked', G.airplay );
		$( '#spotify' ).prop( 'checked', G.spotify );
		$( '#setting-spotify' ).toggleClass( 'hide', !G.spotify );
		$( '#upnp' ).prop( 'checked', G.upnp );
//		$( '#setting-upnp' ).toggleClass( 'hide', !G.upnp );
		$( '#chromium' ).prop( 'checked', G.chromium );
		$( '#setting-chromium' ).toggleClass( 'hide', !G.chromium );
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
		$( '#scrobbler' ).prop( 'checked', G.scrobbler );
		$( '#setting-scrobbler' ).toggleClass( 'hide', !G.scrobbler );
		$( '#login' ).prop( 'checked', G.login );
		$( '#setting-login' ).toggleClass( 'hide', !G.login );
		$( '#avahi' ).prop( 'checked', G.avahi );
		$( '#avahiname' ).text( G.hostname.toLowerCase() );
		$( '#autoplay' ).prop( 'checked', G.autoplay );
		$( '#accesspoint' ).prop( 'checked', G.hostapd );
		$( '#setting-accesspoint' ).toggleClass( 'hide', !G.hostapd );
		services.forEach( function( id ) {
			codeToggle( id, 'status' );
		} );
		resetLocal();
		showContent();
	}, 'json' );
}
refreshData();
//---------------------------------------------------------------------------------------
$( '#airplay' ).click( function( e ) {
	G.airplay = $( this ).prop( 'checked' );
	notify( 'AirPlay Renderer', G.airplay, 'airplay' );
	bash( [ 'airplay', G.airplay ], codeToggle( 'shairport-sync', 'status' ) );
} );
$( '#snapclient' ).click( function( e ) {
	G.snapclient = $( this ).prop( 'checked' );
	$( '#setting-snapclient' ).toggleClass( 'hide', !G.snapclient );
	notify( 'SnapClient Renderer', G.snapclient, 'snapcast' );
	bash( [ 'snapclient', G.snapclient ], codeToggle( 'snapclient', 'status' ) );
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
				bash( [ 'snapclientset', G.snaplatency, G.snapserverpw ] );
			}
		}
	} );
} );
$( '#spotify' ).click( function() {
	G.spotify = $( this ).prop( 'checked' );
	$( '#setting-spotify' ).toggleClass( 'hide', !G.spotify );
	notify( 'Spotify Connect', G.spotify, 'spotify' );
	bash( [ 'spotify', G.spotify ], codeToggle( 'spotifyd', 'status' ) );
} );
$( '#setting-spotify' ).click( function() {
	bash( [ 'aplaydevices' ], function( devices ) {
		var devices = devices.split( '\n' );
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
			, boxwidth    : 'max'
			, preshow     : function() {
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
					bash( [ 'spotifyset', device ] );
				}
			}
		} );
	} );
} );
$( '#upnp' ).click( function( e ) {
	G.upnp = $( this ).prop( 'checked' );
	notify( 'UPnP Renderer', G.upnp, 'upnp fa-s' );
	bash( [ 'upnp', G.upnp ], codeToggle( 'upmpdcli', 'status' ) );
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
	bash( [ 'snapcast', G.snapcast ], codeToggle( 'snapserver', 'status' ) );
} );
$( '#streaming' ).click( function( e ) {
	G.streaming = $( this ).prop( 'checked' );
	notify( 'HTTP Streaming', G.streaming, 'mpd' );
	bash( [ 'streaming', G.streaming ] );
} );
$( '#chromium' ).click( function( e ) {
	G.localbrowser = $( this ).prop( 'checked' );
	$( '#setting-chromium' ).toggleClass( 'hide', !G.localbrowser );
	notify( 'Chromium - Browser on RPi', G.localbrowser, 'chromium blink' );
	bash( [ 'localbrowser', G.localbrowser ], codeToggle( 'localbrowser', 'status' ) );
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
$( '#setting-chromium' ).click( function( e ) {
	info( {
		  icon        : 'chromium'
		, title       : 'Browser on RPi'
		, content     : localbrowserinfo
		, preshow     : function() {
			$( '#infoTextBox1' ).val( G.zoom );
			$( '#infoTextBox' ).val( G.screenoff / 60 );
			$( 'input[name=inforadio]' ).val( [ G.rotate ] );
			$( '#infoCheckBox input:eq( 0 )' ).prop( 'checked', G.cursor );
			if ( G.lcd ) $( '#infoRadio' ).after( '<gr>(Rotate GPIO LCD: Reboot required.)</gr>' );
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
			var screenoff = $( '#infoTextBox' ).val() * 60;
			var zoom = parseFloat( $( '#infoTextBox1' ).val() ) || 1;
			zoom = zoom < 2 ? ( zoom < 0.5 ? 0.5 : zoom ) : 2;
			if ( rotate !== G.rotate ) {
				G.rotate = rotate;
			} else {
				rotate = ''
			}
			if ( screenoff !== G.screenoff ) {
				G.screenoff = screenoff;
			} else {
				screenoff = ''
			}
			if ( cursor === G.cursor && rotate === '' && screenoff === '' && zoom === G.zoom ) return
			
			notify( 'Chromium - Browser on RPi', 'Change ...', 'chromium blink' );
			if ( rotate !== '' && cursor === G.cursor && screenoff === '' && zoom === G.zoom ) { // rotate only
				if ( G.lcd ) {
					var degree = { CW: 0, NORMAL: 90, CCW: 180, UD: 270 }
					bash( [ 'rotatelcd', degree[ rotate ] ] );
				} else {
					bash( [ 'rotate', rotate ] );
				}
				return
			}
			
			if ( screenoff !== '' && cursor === G.cursor && rotate === '' && zoom === G.zoom ) { // screenoff only
				bash( [ 'screenoff', screenoff ] );
				return
			}
			
			G.cursor = cursor;
			G.zoom = zoom;
			bash( [ 'localbrowserset', rotate, screenoff, cursor, zoom ] );
		}
	} );
} );
$( '#samba' ).click( function( e ) {
	G.samba = $( this ).prop( 'checked' );
	$( '#setting-samba' ).toggleClass( 'hide', !G.samba );
	notify( 'Samba - File Sharing', G.samba, 'network blink' );
	bash( [ 'samba', G.samba ], codeToggle( 'smb', 'status' ) );
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
				bash( [ 'sambaset', G.writesd, G.writeusb ] );
			}
		}
	} );
} );
$( '#scrobbler' ).click( function() {
	var mpdscribble = $( this ).prop( 'checked' );
	if ( mpdscribble && !G.mpdscribbleuser ) {
		$( '#setting-scrobbler' ).click();
	} else {
		notify( 'Scrobbler', mpdscribble, 'lastfm' );
		bash( [ 'mpdscribble', mpdscribble ], function( std ) {
			G.mpdscribble = std != -1 ? true : false;
			$( '#setting-scrobbler' ).toggleClass( 'hide', !G.mpdscribble );
			codeToggle( 'mpdscribble', 'status' );
		} );
	}
} );
$( '#setting-scrobbler' ).click( function() {
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
		} );
		}
	} );
} );
$( '#login' ).click( function() {
	G.login = $( this ).prop( 'checked' );
	$( '#setting-login' ).toggleClass( 'hide', !G.login );
	notify( 'Password Login', G.login, 'lock' );
	bash( [ 'login', G.login ] );
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
	bash( [ 'autoplay', G.autoplay ] );
} );
$( '#accesspoint' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( checked && G.wlanup ) {
		info( {
			  icon      : 'network'
			, title     : 'RPi Access Point'
			, message   : '<wh>Wi-Fi is currently connected.</wh>'
						 +'<br>Disconnect and continue?'
			, ok        : function() {
				G.hostapd = true;
				$( '#setting-accesspoint' ).removeClass( 'hide' );
				notify( 'RPi Access Point', true, 'wifi-3' );
				bash( [ 'accesspoint', true, G.hostapdip ] );
			}
		} )
		return
	}
	
	G.hostapd = checked;
	$( '#setting-accesspoint' ).toggleClass( 'hide', !G.hostapd );
	notify( 'RPi Access Point', G.hostapd, 'wifi-3' );
	bash( [ 'accesspoint', G.hostapd, G.hostapdip ] );
} );
$( '#setting-accesspoint' ).click( function() {
	info( {
		  icon      : 'network'
		, title     : 'RPi Access Point Settings'
		, message   : 'Password - at least 8 characters'
		, textlabel : [ 'Password', 'IP' ]
		, textvalue : [ G.passphrase, G.hostapdip ]
		, textrequired : [ 0, 1 ]
		, ok      : function() {
			var ip = $( '#infoTextBox1' ).val();
			var passphrase = $( '#infoTextBox' ).val();
			if ( ip === G.hostapdip && passphrase === G.passphrase ) return
			
			if ( passphrase.length < 8 ) {
				info( 'Password must be at least 8 characters.' );
				return
			}
			
			G.hostapdip = ip;
			G.passphrase = passphrase;
			var ips = ip.split( '.' );
			var ip3 = ips.pop();
			var ip012 = ips.join( '.' );
			var iprange = ip012 +'.'+ ( +ip3 + 1 ) +','+ ip012 +'.254,24h';
			notify( 'RPi Access Point', 'Change ...', 'wifi-3' );
			bash( [ 'accesspointset', iprange, ip, passphrase ] );
		}
	} );
} );

} );
