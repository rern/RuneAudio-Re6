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
};
onVisibilityChange( function( visible ) {
	if ( visible ) {
		pushstream.connect();
	} else {
		clearIntervalAll();
		pushstream.disconnect();
	}
} );
window.addEventListener( 'orientationchange', function() {
	if ( G.playback ) $( '#page-playback' ).addClass( 'hide' );
	setTimeout( function() {
		if ( G.playback ) {
			displayPlayback();
			setTimeout( scrollLongText, 300 );
			$( '#page-playback' ).removeClass( 'hide' );
		} else if ( G.library ) {
			if ( G.librarylist || G.savedlist ) {
				if ( $( '.licover' ).length ) {
					$( '#lib-list p' ).css( 'min-height', ( G.bars ? 40 : 0 ) +'px' );
					$( '.liinfo' ).css( 'width', ( window.innerWidth - $( '.licoverimg img' ).width() - 50 ) +'px' );
				} else {
					$( '#lib-list p' ).css( 'min-height', window.innerHeight - ( G.bars ? 130 : 90 ) +'px' );
				}
			}
		} else {
			if ( G.playlist && !G.savedlist && !G.savedplaylist ) {
				getTitleWidth();
				setTitleWidth();
				setPlaylistScroll()
				$( '#pl-list p' ).css( 'min-height', window.innerHeight - ( G.bars ? 277 : 237 ) +'px' );
			}
		}
	}, 100 );
} );

var pushstream = new PushStream( {
	  modes                                 : 'websocket'
	, timeout                               : 5000
	, reconnectOnChannelUnavailableInterval : 5000
} );
var streams = [ 'airplay', 'bookmark', 'coverart', 'display', 'gpio', 'mpdplayer', 'mpdupdate',
	'notify', 'option', 'order', 'package', 'playlist', 'reload', 'seek', 'snapcast', 'spotify', 'volume', 'volumenone', 'webradio' ];
streams.forEach( function( stream ) {
	pushstream.addChannel( stream );
} );
pushstream.connect();
pushstream.onstatuschange = function( status ) {
	if ( status === 2 ) {
		getPlaybackStatus();
	} else if ( status === 0 ) { // disconnect
		bannerHide();
	}
}
pushstream.onmessage = function( data, id, channel ) {
	switch( channel ) {
		case 'airplay':    psAirplay( data );    break;
		case 'bookmark':   psBookmark( data );   break;
		case 'coverart':   psCoverart( data );   break;
		case 'display':    psDisplay( data );    break;
		case 'gpio':       psGPIO( data );       break;
		case 'mpdplayer':  psMpdPlayer( data );  break;
		case 'mpdupdate' : psMpdUpdate( data );  break;
		case 'notify':     psNotify( data );     break;
		case 'option':     psOption( data );     break;
		case 'order':      psOrder( data );      break;
		case 'package':    psPackage( data );    break;
		case 'playlist':   psPlaylist( data );   break;
		case 'reload':     psReload( data );     break;
		case 'restore':    psRestore( data );    break;
		case 'seek':       psSeek( data );       break;
		case 'snapcast':   psSnapcast( data );   break;
		case 'spotify':    psSpotify( data );    break;
		case 'volume':     psVolume( data );     break;
		case 'volumenone': psVolumeNone( data ); break;
		case 'webradio':   psWebradio( data );   break;
	}
}
function psAirplay( data ) {
	$.each( data, function( key, value ) {
		G.status[ key ] = value;
	} );
	renderPlayback();
	setButtonControl();
	displayTopBottom();
}
function psBookmark( data ) {
	if ( G.bookmarkedit ) return
	
	clearTimeout( G.debounce );
	G.debounce = setTimeout( function() {
		if ( 'html' in data ) {
			$( '#lib-mode-list' ).append( data.html );
		} else {
			var $bookmark = $( '.lib-mode' ).filter( function() {
				return $( this ).find( '.lipath' ) === data.path;
			} );
			if ( data.type === 'delete' ) {
				$bookmark.remove();
			} else {
				$bookmark.find( '.bklabel' ).text( data.name );
			}
		}
		if ( 'order' in data ) G.display.order = data.order;
	}, G.debouncems );
}
function psCoverart( data ) {
	clearTimeout( G.timeoutCover );
	var src = data.url;
	var url = decodeURIComponent( data.url );
	var path = url.substr( 0, url.lastIndexOf( '/' ) );
	switch( data.type ) {
		case 'coverart':
			G.status.coverart = src;
			if ( G.playback ) $( '#coverart' ).attr( 'src', src );
/*			if ( G.playback ) {
				$( '#coverart' ).attr( 'src', src );
			} else if ( G.library ) {
				if ( !G.librarylist ) return
				
				if ( $( '.licover' ).length ) {
					if ( $( '.licover .lipath' ).text() === decodeURIComponent( src ).slice( 9, -21 ) ) $( '.licoverimg img' ).attr( 'src', src );
				} else {
					var query = G.query[ G.query.length - 1 ];
					list( query, function( data ) {
						data.path = query.path;
						data.modetitle = query.modetitle;
						renderLibraryList( data );
					}, 'json' );
				}
			} else {
				$( '#tab-playlist' ).click();
			}*/
			break;
		case 'bookmarks':
			var $li = $( '.bookmark' ).filter( function() {
				return $( this ).find( '.lipath' ).text() === path;
			} );
			if ( $li.length ) $li.attr( 'src', src );
			break;
		case 'webradio':
			G.status.coverartradio = src;
			if ( G.mode === 'webradio' ) {
				var srcnoext = src.slice( 0, -15 );
				var srcthumb = srcnoext +'-thumb'+ src.slice( -15 );
				var $el = webradioIcon( srcnoext );
				$el.replaceWith( '<img class="lazy iconthumb lib-icon loaded" data-target="#menu-webradio" data-ll-status="loaded" src="'+ srcthumb +'">' );
			}
			if ( G.playback ) {
				$( '#coverart' )
					.attr( 'src', src )
					.css( { 'border-radius': '', opacity: '' } );
			} else if ( G.playlist ) {
				$( '#tab-playlist' ).click();
			}
			break;
		case 'webradioreset':
			G.status.coverartradio = '';
			if ( G.mode === 'webradio' ) {
				var $el = webradioIcon( src );
				$el.replaceWith( '<i class="fa fa-webradio lib-icon" data-target="#menu-webradio"></i>' );
			}
			if ( G.playback ) {
				$( '.edit' ).remove();
				var stop = G.status.state === 'stop';
				if ( stop || !G.status.coverart ) {
					$( '#coverart' )
						.attr( 'src', stop ? vustop : vu )
						.css( { 'border-radius': '18px', opacity: '' } );
				}
			} else if ( G.playlist ) {
				$( '#tab-playlist' ).click();
			}
			break;
	}
	bannerHide();
}
function psDisplay( data ) {
	if ( G.local ) return
	
	var hidecover = G.display.hidecover;
	$.each( data, function( key, val ) {
		G.display[ key ] = val;
	} );
	if ( G.playback ) {
		setButtonControl();
		renderPlayback();
		displayPlayback();
	} else if ( G.library ) {
		if ( !G.librarylist ) {
			renderLibrary();
		} else if ( $( '.licover' ).length ) {
			if ( hidecover && !G.display.hidecover ) {
				var query = G.query[ G.query.length - 1 ];
				list( query, function( data ) {
					data.path = query.path;
					data.modetitle = query.modetitle;
					renderLibraryList( data );
				}, 'json' );
			} else {
				setTrackCoverart();
			}
		} else if ( $( '#lib-list .coverart' ).length && G.albumbyartist !== G.display.albumbyartist ) {
			G.query = [];
			$( '#mode-album' ).click();
		}
	}
	displayTopBottom();
}
function psGPIO( response ) { // on receive broadcast
	clearInterval( G.gpiotimer );
	if ( 'on' in response ) {
		$( '#device'+ response.on ).removeClass( 'gr' );
	} else if ( 'off' in response ) {
		$( '#device'+ response.off ).addClass( 'gr' );
	} else if ( 'done' in response ) {
		G.status.gpioon = response.done;
		setButtonOptions();
		$( '#infoX' ).click();
	}
	if ( !( 'state' in response ) ) return
		
	var state = response.state;
	G.status.gpioon = state;
	if ( state === 'RESET' ) {
		$( '#infoX' ).click();
	} else if ( state === 'IDLE' ) {
		if ( !$( '#infoOverlay' ).hasClass( 'hide' ) ) return
		
		var delay = response.delay;
		info( {
			  icon        : 'gpio'
			, title       : 'GPIO Idle Timer'
			, message     : 'Power Off Countdown:<br><br>'
						   + stopwatch +'&ensp;<white>'+ delay +'</white>'
			, oklabel     : 'Reset'
			, ok          : function() {
				bash( [ 'gpiotimerreset' ] );
			}
		} );
		G.gpiotimer = setInterval( function() {
			if ( delay === 1 ) {
				G.status.gpioon = false;
				setButtonOptions();
				$( '#infoX' ).click();
				clearInterval( G.gpiotimer );
			}
			$( '#infoMessage white' ).text( delay-- );
		}, 1000 );
	} else {
		var devices = ''
		$.each( response.order, function( i, val ) {
			if ( i === 0 ) {
				var color = state ? '' : 'class="gr"';
			} else {
				var color = state ? 'class="gr"' : '';
			}
			devices += '<br><a id="device'+ ( i + 1 ) +'" '+ color +'>'+ val +'</a>';
		} );
		info( {
			  icon      : 'gpio'
			, title     : 'GPIO'
			, message   : stopwatch +' <wh>Power '+ ( state ? 'ON' : 'OFF' ) +'</wh>'
			, msghr     : 1
			, footer    : devices.slice( 4 ) // remove 1st <br>
			, nobutton  : 1
		} );
	}
}
function psMpdPlayer( data ) {
	$.each( data, function( key, value ) {
		G.status[ key ] = value;
	} );
	setButtonControl();
	if ( G.playlist ) {
		setPlaylistScroll();
	} else if ( G.playback ) {
		if ( G.display.coverart ) {
			if ( data.state === 'stop' && data.webradio ) {
				G.status.coverart = '';
				data.coverart = '';
			} else {
				if ( !data.coverart && G.status.coverart ) {
					if ( data.webradio ) {
						var coverart = data.coverartradio || ( data.state === 'stop' ? vustop : vu );
					} else {
						var coverart = coverrune;
					}
					G.timeoutCover = setTimeout( function() {
						G.status.coverart = '';
						$( '#coverart' ).attr( 'src', coverart );
					}, data.Title ? 3000 : 0 );
					delete data.coverart;
				}
			}
		}
		bannerHide();
		renderPlayback();
		displayPlayback();
	}
}
function psMpdUpdate( data ) {
	var $elupdate = $( '#tab-library, #button-library, #i-update, #ti-update' );
	$( '#i-update, #ti-update' ).addClass( 'hide' );
	if ( typeof data === 'number' ) {
		G.status.updating_db = true;
		if ( G.localhost ) return
		
		if ( G.bars ) {
			if ( !G.localhost ) $( '#tab-library, #button-library' ).addClass( 'blink' );
		} else {
			if ( !G.localhost ) $( '#button-library' ).addClass( 'blink' );
			$( '#'+ ( G.display.time ? 'ti' : 'i' ) +'-update' ).removeClass( 'hide' );
		}
	} else {
		G.status.updating_db = false;
		$( '#tab-library, #button-library, #i-update, #ti-update' )
			.removeClass( 'fa-file-wave' )
			.addClass( 'fa-library' );
		$( '#tab-library, #button-library, .lib-icon.blink' ).removeClass( 'blink' );
		banner( 'Library Update', 'Done', 'library' );
		$( '#lib-mode-list' ).data( 'count', data.title )
		$( '#li-count' ).html( data.song.toLocaleString() +' <i class="fa fa-music gr"></i>' );
		delete data.title;
		$.each( data, function( key, val ) {
			$( '#mode-'+ key ).find( 'grl' ).text( val ? val.toLocaleString() : '' );
		} );
		if ( G.library ) {
			if ( G.mode === 'webradio' ) {
				data.webradio ? $( '#mode-webradio' ).click() : $( '#button-library' ).click();
			} else {
				$( '.lib-icon.blink' ).removeClass( 'blink' );
				var query = G.query[ G.query.length - 1 ];
				if ( query ) {
					list( query, function( data ) {
						data.path = query.path;
						data.modetitle = query.modetitle;
						renderLibraryList( data );
					}, 'json' );
				}
			}
		} else if ( G.playlist && !G.savedlist ) {
			$( '#tab-playlist' ).click();
		}
	}
}
function psNotify( data ) {
	banner( data.title, data.text, data.icon, data.delay );
	if ( data.icon === 'file-wave' ) {
		$( '#tab-library, #button-library, #i-update, #ti-update' )
			.removeClass( 'fa-library' )
			.addClass( 'fa-file-wave' );
	}
	if ( data.title === 'Power' ) {
		data.text === 'Off ...' ? loader( 'show', 'splash' ) : loader( 'show' );
	} else if ( data.title === 'AirPlay' && data.text === 'Stop ...' ) {
		loader( 'show' );
	}
}
function psOption( data ) {
	if ( G.local ) return
	
	var option = Object.keys( data )[ 0 ];
	G.status[ option ] = Object.values( data )[ 0 ];
	setButtonOptions();
}
function psOrder( data ) {
	if ( G.local ) return
	
	G.display.order = data;
	orderLibrary();
}
function psPackage( data ) {
	if ( G.local ) return
	
	$( '#'+ data.pkg )
			.data( { active: data.start, enabled: data.enable } )
			.find( 'img' ).toggleClass( 'on', data.start );
}
function psPlaylist( data ) {
	if ( data == -1 ) {
		renderPlaylist( -1 );
	} else if ( 'html' in data ) {
		renderPlaylist( data );
	} else if ( data.playlist === 'save' ) {
		if ( G.savedlist ) $( '#button-pl-open' ).click();
	} else {
		var name = $( '#pl-path .lipath' ).text();
		if ( G.savedplaylist && data.playlist === name ) renderSavedPlaylist( name );
	}
}
function psReload( data ) {
	location.href = '/';
}
function psRestore( data ) {
	if ( data.restore === 'done' ) {
		banner( 'Restore Settings', 'Done', 'sd' );
		setTimeout( function() {
			location.href = '/';
		}, 2000 );
	} else {
		loader( 'show' );
		banner( 'Restore Settings', 'Restart '+ data.restore +' ...', 'sd blink', -1 );
	}
}
function psSeek( data ) {
	local();
	G.status.elapsed = data.elapsed;
	if ( data.state ) G.status.state = 'pause';
	renderPlayback();
}
function psSnapcast( data ) {
	if ( data !== -1 ) {
		var cmd = '/srv/http/bash/snapcast.sh ';
		cmd += 'add' in data ? ' add '+ data.add : ' remove '+ data.remove;
		bash( cmd );
	} else {
		bash( 'systemctl stop snapclient && systemctl start mpd', function() {
			getPlaybackStatus();
		} );
	}
}
function psSpotify( data ) {
	if ( G.playback ) {
		if ( 'pause' in data ) {
			G.status.state = 'pause'
			G.status.elapsed = data.pause;
		} else {
			$.each( data, function( key, value ) {
				G.status[ key ] = value;
			} );
		}
		renderPlayback();
		setButtonControl();
		displayTopBottom();
	} else {
		$( '#tab-playback' ).click();
	}
}
function psVolume( data ) {
	if ( G.local ) return
	
	if ( 'disable' in data ) {
		$( '#vol-group .btn, .volmap' ).toggleClass( 'disabled', data.disable );
		return
	}
	clearTimeout( G.debounce );
	G.debounce = setTimeout( function() {
		var type = data.type;
		var val = data.val;
		if ( type === 'mute' ) {
			G.status.volume = 0;
			G.status.volumemute = val;
			$volumeRS.setValue( 0 );
			volColorMute( val );
		} else {
			G.status.volume = val;
			G.status.volumemute = 0;
			$volumeRS.setValue( val );
			volColorUnmute();
		}
		$volumehandle.rsRotate( - $volumeRS._handle1.angle );
	}, G.debouncems );
}
function psVolumeNone( data ) {
	if ( data.volumenone ) {
		var existing = G.display.volumenone;
		G.display.volumenone = data.volumenone;
		if ( data.volumenone !== existing && G.playback ) displayPlayback();
	} else {
		G.display.volumenone = false;
		bash( "awk '/volume/ {print $NF}' /srv/http/data/mpd/mpdstate", function( data ) {
			G.status.volume = data;
			if ( G.playback ) {
				$volumeRS.setValue( G.status.volume );
				displayPlayback();
			}
		} );
	}
}
function psWebradio( data ) {
	$( '#mode-webradio grl' ).text( data )
	if ( G.librarylist ) $( '#mode-webradio grl' ).click();
}
function webradioIcon( srcnoext ) {
	var radiourl = decodeURIComponent( srcnoext )
					.split( '/' ).pop()
					.replace( /\|/g, '/' );
	return $( '#lib-list li' ).filter( function() {
		return $( this ).find( '.lipath' ).text() === radiourl;
	} ).find( '.lib-icon' );
}

