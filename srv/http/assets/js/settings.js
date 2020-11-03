function bash( command, callback, json ) {
	if ( typeof command === 'string' ) {
		var args = { cmd: 'bash', bash : command }
	} else {
		var args = { cmd: 'sh', sh: [ page +'.sh' ].concat( command ) }
	}
	$.post( 
		  cmdphp
		, args
		, callback || null
		, json || null
	);
}
function notify( title, message, icon ) {
	local = 1;
	if ( typeof message === 'boolean' || typeof message === 'number' ) var message = message ? 'Enable ...' : 'Disable ...';
	banner( title, message, icon +' blink', -1 );
}
function codeToggle( target, id, fn ) {
	if ( !$( target ).hasClass( 'help' ) ) $( '#code'+ id ).hasClass( 'hide' ) ? fn() : $( '#code'+ id ).addClass( 'hide' );
}
function getReset( callback ) {
	$.post( cmdphp, {
		  cmd  : 'exec'
		, exec : 'cat '+ filereboot
	}, function( lines ) {
		G.reboot = lines || [];
		if ( callback ) callback();
	}, 'json' );
}
function resetLocal( ms ) {
	local = 0;
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
function statusColor( status ) {
	return status
				.replace( /(active \(running\))/, '<grn>$1</grn>' )
				.replace( /(inactive \(dead\))/, '<red>$1</red>' );
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
	if ( data.page === page ) refreshData();
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
		refreshData();
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
var local = 0;
var intervalcputime;
var intervalscan;
var page = location.href.split( '=' ).pop();
var reboot = '';
var cmdphp = 'cmd.php';
var dirsystem = '/srv/http/data/system';
var filereboot = '/srv/http/data/shm/reboot';

document.title = 'R+R '+ ( page === 'mpd' ? 'MPD' : page.charAt( 0 ).toUpperCase() + page.slice( 1 ) );

$( '#close' ).click( function() {
	if ( page === 'system' || page === 'features' ) {
		getReset( function() {
			if ( G.reboot.length ) {
				info( {
					  icon    : 'sliders'
					, title   : 'System Setting'
					, message : 'Reboot required for:'
							   +'<br><br><w>'+ G.reboot.join( '<br>' ) +'</w>'
					, cancel  : function() {
						G.reboot = [];
						bash( 'rm -f '+ filereboot );
					}
					, ok      : function() {
						$.post( cmdphp, {
							  cmd : 'sh'
							, sh  : [ 'cmd.sh', 'power', 'reboot' ]
						} );
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
	location.reload();
} );
$( '#help' ).click( function() {
	var eltop = $( 'heading' ).filter( function() {
		return this.getBoundingClientRect().top > 0
	} )[ 0 ]; // return 1st element
	var offset0 = eltop.getBoundingClientRect().top;
	$( this ).toggleClass( 'blue' );
	$( '.help-block' ).toggleClass( 'hide', $( '.help-block:not(.hide)' ).length !== 0 );
	$( window ).scrollTop( eltop.offsetTop - offset0 );
} );
$( '.help' ).click( function() {
	$( this ).parent().parent().find( '.help-block' ).toggleClass( 'hide' );
	$( '#help' ).toggleClass( 'blue', $( '.help-block:not(.hide)' ).length !== 0 );
} );
