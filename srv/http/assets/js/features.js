$( function() { // document ready start >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

refreshData = function() { // system page: use resetLocal() to aviod delay
	bash( '/srv/http/bash/features-data.sh', function( list ) {
		G = list;
		G.reboot = list.reboot ? list.reboot.split( '\n' ) : [];
		$( '#shairport-sync' ).prop( 'checked', G[ 'shairport-sync' ] );
		$( '#spotifydd' ).prop( 'checked', G.spotifyd );
		$( '#setting-spotifyd' ).toggleClass( 'hide', !G.spotifyd );
		$( '#upmpdcli' ).prop( 'checked', G.upmpdcli );
//		$( '#setting-upnp' ).toggleClass( 'hide', !G.upnp );
		$( '#localbrowser' ).prop( 'checked', G.localbrowser );
		$( '#setting-localbrowser' ).toggleClass( 'hide', !G.localbrowser );
		$( '#smb' ).prop( 'checked', G.smb );
		$( '#setting-smb' ).toggleClass( 'hide', !G.smb );
		$( '#snapserver' ).prop( 'checked', G.snapserver );
		if ( G.snapserver ) {
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
		$( '#mpdscribble' ).prop( 'checked', G.mpdscribble );
		$( '#setting-mpdscribble' ).toggleClass( 'hide', !G.mpdscribble );
		$( '#login' ).prop( 'checked', G.login );
		$( '#setting-login' ).toggleClass( 'hide', !G.login );
		$( '#autoplay' ).prop( 'checked', G.autoplay );
		$( '#hostapd' ).prop( 'checked', G.hostapd );
		$( '#setting-hostapd' ).toggleClass( 'hide', !G.hostapd );
		services.forEach( function( id ) {
			codeToggle( id, 'status' );
		} );
		resetLocal();
		showContent();
	}, 'json' );
}
refreshData();
//---------------------------------------------------------------------------------------
$( '#shairport-sync' ).click( function( e ) {
	var checked = $( this ).prop( 'checked' );
	notify( 'AirPlay Renderer', checked, 'airplay' );
	bash( [ 'shairport-sync', checked ] );
} );
$( '#snapclient' ).click( function( e ) {
	var checked = $( this ).prop( 'checked' );
	if ( G.snapclientset ) {
		notify( 'SnapClient Renderer', checked, 'snapcast' );
		bash( [ 'snapclient', checked ] );
	} else {
		$( '#setting-snapclient' ).click();
	}
} );
$( '#setting-snapclient' ).click( function() {
	info( {
		  icon          : 'snapcast'
		, title         : 'SnapClient'
		, message       : 'Sync client to server:'
		, textlabel     : 'Latency <gr>(ms)</gr>'
		, textvalue     : G.snaplatency || 800
		, passwordlabel : 'Password'
		, footer        : '<px40/>(If Snapcast server password '
						+'<br><px40/>not the same as this client.)'
		, preshow       : function() {
			$( '#infoPasswordBox' ).val( G.snapserverpw );
		}
		, cancel        : function() {
			if ( !G.snaplatency ) $( '#snapclient' ).prop( 'checked', 0 );
		}
		, ok            : function() {
			var snaplatency = Math.abs( $( '#infoTextBox' ).val() );
			var snapserverpw = $( '#infoPasswordBox' ).val();
			if ( snaplatency !== G.snaplatency || snapserverpw !== G.snapserverpw ) {
				notify( 'Snapclient', 'Change ...', 'snapcast' );
				bash( [ 'snapclientset', snaplatency, snapserverpw ] );
			}
		}
	} );
} );
$( '#spotifyd' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	notify( 'Spotify Connect', checked, 'spotify' );
	bash( [ 'spotifyd', checked ] );
} );
$( '#setting-spotifyd' ).click( function() {
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
			, checked     : G.spotifydset
			, boxwidth    : 'max'
			, cancel      : function() {
				if ( !G.spotifydset ) $( '#spotify' ).prop( 'checked', 0 );
			}
			, ok          : function() {
				var device = $( '#infoSelectBox option:selected' ).text();
				if ( device !== G.spotifydset ) {
					notify( 'Spotify Renderer', 'Change ...', 'spotify' );
					bash( [ 'spotifyset', device ] );
				}
			}
		} );
	} );
} );
$( '#upmpdcli' ).click( function( e ) {
	var checked = $( this ).prop( 'checked' );
	notify( 'UPnP Renderer', checked, 'upnp fa-s' );
	bash( [ 'upmpdcli', checked ] );
} );
$( '#snapserver' ).click( function( e ) {
	var checked = $( this ).prop( 'checked' );
	notify( 'Snapcast - Sync Streaming Server', checked, 'snapcast' );
	bash( [ 'snapserver', checked ] );
} );
$( '#streaming' ).click( function( e ) {
	var checked = $( this ).prop( 'checked' );
	notify( 'HTTP Streaming', checked, 'mpd' );
	bash( [ 'streaming', checked ] );
} );
$( '#localbrowser' ).click( function( e ) {
	var checked = $( this ).prop( 'checked' );
	if ( G.localbrowserset ) {
		notify( 'Chromium - Browser on RPi', checked, 'chromium' );
		bash( [ 'localbrowser',checked ] );
	} else {
		$( '#setting-localbrowser' ).click();
	}
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
		, cancel      : function() {
			if ( !G.localbrowserset ) $( '#localbrowser' ).prop( 'checked', 0 );
		}
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
			
			notify( 'Chromium - Browser on RPi', 'Change ...', 'chromium' );
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
$( '#smb' ).click( function( e ) {
	var checked = $( this ).prop( 'checked' );
	if ( G.smb ) {
		notify( 'Samba - File Sharing', checked, 'network' );
		bash( [ 'smb', checked ] );
	} else {
		$( '#setting-smb' ).click();
	}
} );
$( '#setting-smb' ).click( function() {
	info( {
		  icon     : 'network'
		, title    : 'Samba File Sharing'
		, message  : '<wh>Write</wh> permission:</gr>'
		, checkbox : { '<gr>/mnt/MPD/</gr>SD': 1, '<gr>/mnt/MPD/</gr>USB': 1 }
		, preshow  : function() {
			$( '#infoCheckBox input:eq( 0 )' ).prop( 'checked', G.writesd );
			$( '#infoCheckBox input:eq( 1 )' ).prop( 'checked', G.writeusb );
		}
		, cancel   : function() {
			if ( !G.smbset ) $( '#smb' ).prop( 'checked', 0 );
		}
		, ok       : function() {
			var writesd = $( '#infoCheckBox input:eq( 0 )' ).prop( 'checked' );
			var writeusb = $( '#infoCheckBox input:eq( 1 )' ).prop( 'checked' );
			if ( writesd !== G.writesd || writeusb !== G.writeusb ) {
				G.writesd = writesd;
				G.writeusb = writeusb;
				notify( 'Samba - File Sharing', 'Change ...', 'network' );
				bash( [ 'smbset', G.writesd, G.writeusb ] );
			}
		}
	} );
} );
$( '#mpdscribble' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( G.mpdscribble ) {
		notify( 'Scrobbler', checked, 'lastfm' );
		bash( [ 'mpdscribble', checked ] );
	} else {
		$( '#setting-mpdscribble' ).click();
	}
} );
$( '#setting-mpdscribble' ).click( function() {
	info( {
		  icon          : 'lastfm'
		, title         : 'Scrobbler'
		, textlabel     : 'Username'
		, textvalue     : G.mpdscribbleset
		, passwordlabel : 'Password'
		, cancel        : function() {
			if ( !G.mpdscribbleset ) $( '#mpdscribble' ).prop( 'checked', 0 );
		}
		, ok            : function() {
			G.mpdscribbleset = $( '#infoTextBox' ).val().replace( /(["&()\\])/g, '\$1' );
			var password = $( '#infoPasswordBox' ).val().replace( /(["&()\\])/g, '\$1' );
			notify( 'Scrobbler', G.mpdscribble ? 'Change ...' : 'Enable ...', 'lastfm' );
			bash( [ 'mpdscribbleset', G.mpdscribbleset, password ], function( std ) {
				if ( std == -1 ) {
					info( {
						  icon    : 'lastfm'
						, title   : 'Scrobbler'
						, message : 'Lastfm Login failed.'
					} );
				}
		} );
		}
	} );
} );
$( '#login' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( G.loginset ) {
		notify( 'Password Login', checked, 'key' );
		bash( [ 'login', checked ] );
	} else {
		$( '#setting-login' ).click();
	}
} );
$( '#setting-login' ).click( function() {
	info( {
		  icon          : 'lock'
		, title         : 'Change Password'
		, passwordlabel : ( G.loginset ? [ 'Existing', 'New' ] : 'Password' )
		, pwdrequired   : 1
		, cancel        : function() {
			if ( !G.loginset ) $( '#login' ).prop( 'checked', 0 );
		}
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
$( '#hostapd' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( checked && G.wlanup ) {
		info( {
			  icon      : 'network'
			, title     : 'RPi Access Point'
			, message   : '<wh>Wi-Fi is currently connected.</wh>'
						 +'<br>Disconnect and continue?'
			, ok        : function() {
				$( '#setting-hostapd' ).removeClass( 'hide' );
				notify( 'RPi Access Point', true, 'wifi-3' );
				bash( [ 'hostapd', true, G.hostapdip ] );
			}
		} )
		return
	}
	
	var checked = $( this ).prop( 'checked' );
	if ( G.hostapdset ) {
		notify( 'RPi Access Point', checked, 'wifi-3' );
		bash( [ 'hostapd', checked, G.hostapdip ] );
	} else {
		$( '#setting-hostapd' ).click();
	}
} );
$( '#setting-hostapd' ).click( function() {
	info( {
		  icon         : 'network'
		, title        : 'RPi Access Point Settings'
		, message      : 'Password - at least 8 characters'
		, textlabel    : [ 'Password', 'IP' ]
		, textvalue    : [ G.hostapdpwd, G.hostapdip ]
		, textrequired : [ 0, 1 ]
		, cancel       : function() {
			if ( !G.hostapdset ) $( '#hostapd' ).prop( 'checked', 0 );
		}
		, ok           : function() {
			var ip = $( '#infoTextBox1' ).val();
			var hostapdpwd = $( '#infoTextBox' ).val();
			if ( ip === G.hostapdip && hostapdpwd === G.hostapdpwd ) return
			
			if ( hostapdpwd.length < 8 ) {
				info( 'Password must be at least 8 characters.' );
				return
			}
			
			var ips = ip.split( '.' );
			var ip3 = ips.pop();
			var ip012 = ips.join( '.' );
			var iprange = ip012 +'.'+ ( +ip3 + 1 ) +','+ ip012 +'.254,24h';
			notify( 'RPi Access Point', 'Change ...', 'wifi-3' );
			bash( [ 'hostapdset', iprange, ip, hostapdpwd ] );
		}
	} );
} );

} );
