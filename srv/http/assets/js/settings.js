function bash( command, callback, json ) {
	if ( typeof command === 'string' ) {
		var args = { cmd: 'bash', bash : command }
	} else {
		var args = { cmd: 'sh', sh: [ page +'.sh' ].concat( command ) }
	}
	$.post( 
		  'cmd.php'
		, args
		, callback || null
		, json || null
	);
}
var cmd = {
	  amixer       : '/srv/http/bash/mpd.sh mixerget'
	, aplay        : 'aplay -l'
	, bluetoothctl : 'systemctl -q is-active bluetooth && bluetoothctl show'
	, configtxt    : 'cat /boot/config.txt'
	, crossfade    : 'mpc crossfade'
	, fstab        : 'cat /etc/fstab'
	, ifconfig     : 'ifconfig wlan0'
	, journalctl   : '/srv/http/bash/system.sh statusbootlog'
	, mpdconf      : 'cat /etc/mpd.conf'
	, mount        : 'mount | grep " / \\|MPD"'
	, netctl       : '/srv/http/bash/system.sh statusnetctl'
	, soundprofile : '/srv/http/bash/system.sh soundprofileget'
}
var services = [ 'hostapd', 'localbrowser', 'mpd', 'mpdscribble', 'shairport-sync', 'smb', 'snapclient', 'snapserver', 'spotifyd', 'upmpdcli' ];
function codeToggle( id, target ) {
	id === 'localbrowser' ? resetLocal( 7000 ) : resetLocal();
	if ( $( target ).hasClass( 'help' ) || target.id === 'mpdrestart' ) return // question icon
	
	var $el = $( '#code'+ id );
	if ( target === 'status' && $el.hasClass( 'hide' ) ) return
	
	if ( target === 'status' || $el.hasClass( 'hide' ) ) {
		if ( services.indexOf( id ) !== -1 ) {
			if ( id === 'mpdscribble' ) id+= '@mpd';
			var command = 'systemctl status '+ id;
			var systemctl = 1;
		} else {
			var command = cmd[ id ] +' 2> /dev/null';
			var systemctl = 0;
		}
		var delay = target === 'status' ? 1000 : 0;
		setTimeout( function() {
			bash( command, function( status ) {
				if ( systemctl ) var status = status
								.replace( /(active \(running\))/, '<grn>$1</grn>' )
								.replace( /(inactive \(dead\))/, '<red>$1</red>' )
								.replace( /(failed)/, '<red>$1</red>' );
				$el
					.html( status )
					.removeClass( 'hide' );
				if ( id === 'mpdconf' ) {
					setTimeout( function() {
						$( '#codempdconf' ).scrollTop( $( '#codempdconf' ).height() );
					}, 100 );
				}
			} );
		}, delay );
	} else {
		$el.addClass( 'hide' );
	}
}
function notify( title, message, icon ) {
	if ( typeof message === 'boolean' || typeof message === 'number' ) var message = message ? 'Enable ...' : 'Disable ...';
	banner( title, message, icon +' blink', -1 );
}
function list2JSON( list ) {
		try {
			G = JSON.parse( list );
		} catch( e ) {
			var msg = e.message.split( ' ' );
			var pos = msg.pop();
			var errors = '<red>Errors:</red> '+ msg.join( ' ' ) +' <red>'+ pos +'</red>'
						+'<hr>'
						+ list.slice( 0, pos ) +'<red>&#9646;</red>'+ list.slice( pos );
			$( '.container' ).addClass( 'hide' );
			$( '.codepage' ).html( errors ).removeClass( 'hide' );
			$( '#loader' ).addClass( 'hide' );
			$( '.head' ).removeClass( 'hide' );
			return false
		}
		if ( 'reboot' in G ) G.reboot = G.reboot ? G.reboot.split( '\n' ) : [];
		return true
}
function resetLocal( ms ) {
	setTimeout( function() {
		$( '#bannerIcon i' ).removeClass( 'blink' );
		$( '#bannerMessage' ).text( 'Done' );
	}, ms ? ms - 2000 : 0 );
	setTimeout( bannerHide, ms || 2000 );
}
function showContent() {
	setTimeout( function() {
		$( '#loader' ).addClass( 'hide' );
		$( '.head, .container' ).removeClass( 'hide' );
	}, 300 );
}

var pushstream = new PushStream( { modes: 'websocket' } );
var streams = [ 'refresh', 'reload', 'restore', ];
streams.forEach( function( stream ) {
	pushstream.addChannel( stream );
} );
pushstream.connect();
pushstream.onstatuschange = function( status ) {
	if ( status === 2 ) {
		if ( !$.isEmptyObject( G ) ) {
			$( '#loader' ).addClass( 'hide' );
			refreshData();
		}
	} else {
		$( '#loader' ).removeClass( 'hide' );
		bannerHide();
	}
}
pushstream.onmessage = function( data, id, channel ) {
	switch( channel ) {
		case 'refresh': psRefresh( data ); break;
		case 'reload':  psReload();        break;
		case 'restore': psRestore( data ); break;
	}
}
function psRefresh( data ) {
	if ( data.page === page || data.page === 'all' ) refreshData();
}
function psReload() {
	if ( [ 'localhost', '127.0.0.1' ].indexOf( location.hostname ) !== -1 ) location.reload();
}
function psRestore( data ) {
	if ( data.restore === 'done' ) {
		notify( 'Restore Settings', 'Done', 'sd' );
		setTimeout( function() {
			location.reload();
		}, 2000 );
	} else {
		$( '#loader' ).removeClass( 'hide' );
		notify( 'Restore Settings', 'Restart '+ data.restore +' ...', 'sd blink', -1 );
	}
}
function onVisibilityChange( callback ) {
    var visible = 1;
    function focused() {
        if ( !visible ) callback( visible = 1 );
    }
    function unfocused() {
        if ( visible ) callback( visible = 0 );
    }
    document.addEventListener( 'visibilitychange', function() {
		document.hidden ? unfocused() : focused();
	} );
    window.onpageshow = window.onfocus = focused;
    window.onpagehide = window.onblur = unfocused;
}
onVisibilityChange( function( visible ) {
	if ( page === 'credits' ) return
	
	if ( visible ) {
		if( $( '.codepade' ).hasClass( 'hide' ) ) refreshData();
	} else {
		if ( page === 'networks' ) {
			clearInterval( intervalscan );
		} else if ( page === 'system' ) {
			clearInterval( intervalcputime );
			$( '#refresh i' ).removeClass( 'blink' );
		}
	}
} );
//---------------------------------------------------------------------------------------
G = {}
var intervalcputime;
var intervalscan;
var page = location.href.split( '=' ).pop();
var reboot = '';
var dirsystem = '/srv/http/data/system';
var filereboot = '/srv/http/data/shm/reboot';
var short = window.innerHeight < 570;

document.title = 'R+R '+ ( page === 'mpd' ? 'MPD' : page.charAt( 0 ).toUpperCase() + page.slice( 1 ) );
$( '#bar-bottom i[data-page="'+ page +'"]' ).addClass( 'gra' );

$( '#close' ).click( function() {
	if ( page === 'system' || page === 'features' ) {
		bash( 'cat '+ filereboot, function( lines ) {
			G.reboot = lines;
			if ( G.reboot.length ) {
				info( {
					  icon    : 'sliders'
					, title   : 'System Setting'
					, message : 'Reboot required for:'
							   +'<br><w>'+ G.reboot.replace( /\n/g, '<br>' ) +'</w>'
					, cancel  : function() {
						G.reboot = [];
						bash( 'rm -f '+ filereboot );
					}
					, ok      : function() {
						bash( "/srv/http/bash/cmd.sh power$'\n'reboot" );
						notify( 'Power', 'Reboot ...', 'reboot blink', -1 );
					}
				} );
			} else {
				bash( 'rm -f /srv/http/data/tmp/backup.*' );
				location.href = '/';
			}
		} );
	} else {
		if ( page === 'networks' && $( '#listinterfaces li' ).hasClass( 'bt' ) ) bash( 'bluetoothctl scan off' );
		location.href = '/';
	}
} );
$( '.page-icon' ).click( function() {
	if ( !G ) return
	
	if( $( '.codepage' ).hasClass( 'hide' ) ) {
		$( '.container' ).addClass( 'hide' );
		$( '.codepage' )
			.html( 'Data:<hr>'+ JSON.stringify( G, null, 2 ) )
			.removeClass( 'hide' );
	} else {
		$( '.container' ).removeClass( 'hide' );
		$( '.codepage' ).addClass( 'hide' );
	}
} );
$( '#help' ).click( function() {
	var eltop = $( 'heading' ).filter( function() {
		return this.getBoundingClientRect().top > 0
	} )[ 0 ]; // return 1st element
	var offset0 = eltop.getBoundingClientRect().top;
	if ( $( '.help-block:not(.hide)' ).length > 0 ) {
		$( this ).removeClass( 'blue' );
		$( '.help-block' ).addClass( 'hide' );
		if ( short ) $( '#bar-bottom' ).addClass( 'transparent' );
	} else {
		$( this ).addClass( 'blue' );
		$( '.help-block' ).removeClass( 'hide' );
		if ( short ) $( '#bar-bottom' ).removeClass( 'transparent' );
	}
	$( window ).scrollTop( eltop.offsetTop - offset0 );
} );
$( '.help' ).click( function() {
	$( this ).parent().parent().find( '.help-block' ).toggleClass( 'hide' );
	$( '#help' ).toggleClass( 'blue', $( '.help-block:not(.hide)' ).length !== 0 );
} );
$( '.status' ).click( function( e ) {
	codeToggle( $( this ).data( 'status' ), e.target );
} );
// bar-bottom
if ( short ) {
	$( '#bar-bottom' ).addClass( 'transparent' );
	$( '.container' ).click( function() {
		$( '#bar-bottom' ).addClass( 'transparent' );
	} );
}
$( '#bar-bottom i' ).click( function() {
	if ( $( '#bar-bottom' ).hasClass( 'transparent' ) ) {
		$( '#bar-bottom' ).removeClass( 'transparent' );
	} else {
		location.href = 'settings.php?p='+ $( this ).data( 'page' );
	}
} );
// tap hold
var timer;
$( '#bar-bottom' ).on( 'mousedown touchdown', function() {
	timer = setTimeout( function() {
		location.reload();
	}, 1000 );
} ).on( 'mouseup mouseleave touchup touchleave', function() {
	clearTimeout( timer );
} );
