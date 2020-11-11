$( function() { // document ready start >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

function setMixerType( mixertype ) {
	var $output = $( '#audiooutput option:selected' );
	var name = $output.text();
	var cmd = [];
	if ( mixertype === 'none' ) {
		var card = $output.data( 'card' );
		var hwmixer = $output.data( 'hwmixer' );
	} else {
		var card = '';
		var hwmixer = '';
	}
	notify( 'Mixer Control', 'Change ...', 'mpd' );
	bash( [ 'mixerset', mixertype, name, card, hwmixer ], refreshData );
}
refreshData = function() {
	bash( '/srv/http/bash/mpd-data.sh', function( list ) {
		G = list;
		G.reboot = list.reboot ? list.reboot.split( '\n' ) : [];
		var htmldevices = '';
		$.each( G.devices, function() {
			htmldevices += '<option '
				+'value="'+ this.aplayname +'" '
				+'data-card="'+ this.card +'" '
				+'data-device="'+ this.device +'" '
			if ( this.mixercount ) {
				htmldevices += 'data-hwmixer="'+ this.hwmixer +'" '
							  +'data-mixercount="'+ this.mixercount +'" '
			}
			if ( this.mixertype ) {
				htmldevices += 'data-mixertype="'+ this.mixertype +'" '
			} else if ( this.mixercount ) {
				htmldevices += 'data-mixertype="hardware" '
			} else {
				htmldevices += 'data-mixertype="software" '
			}
			if ( this.mixermanual ) htmldevices += 'data-mixermanual="'+ this.mixermanual +'" ';
			htmldevices += 'data-dop="'+ this.dop +'" '
						  +'>'+ this.name +'</option>';
		} );
		$( '#audiooutput' ).html( htmldevices );
		if ( G.devices.length === 1 ) $( '#audiooutput' ).prop( 'disabled', 1 );
		if ( G.usbdac ) {
			$( '#audiooutput' ).val( G.usbdac );
		} else {
			$( '#audiooutput option' ).filter( function() {
				var $this = $( this );
				return $this.text() === G.audiooutput && $this.val() === G.audioaplayname;
			} ).prop( 'selected', true );
		}
		if ( $( '#audiooutput option:selected' ).data( 'hwmixer' ) ) {
			var mixerhtml =  '<option value="none">Disable</option>'
							+'<option value="hardware">DAC hardware</option>'
							+'<option value="software">MPD software</option>';
			$( '#hwmixertxt' ).show();
		} else {
			var mixerhtml =  '<option value="none">Disable</option>'
							+'<option value="software">MPD software</option>';
			$( '#hwmixertxt' ).hide();
		}
		var $selected = $( '#audiooutput option:selected' );
		cmd.amixer = 'amixer -c '+ $( '#audiooutput option:selected' ).data( 'card' );
		$( '#mixertype' ).html( mixerhtml ).val( $selected.data( 'mixertype' ) );
		$( '#audiooutput, #mixertype' ).selectric( 'refresh' );
		if ( $( '#mixertype' ).val() === 'hardware' && $selected.data( 'mixercount' ) > 1 ) {
			$( '.hwmixer' ).removeClass( 'hide' );
		} else {
			$( '.hwmixer' ).addClass( 'hide' );
		}
		$( '#divmixer' ).toggleClass( 'hide', $selected.data( 'hwmixer' ) === '' );
		var $selected = $( '#audiooutput option:selected' );
		if ( $( '#mixertype' ).val() === 'none'
			&& G.crossfade === 0
			&& G.normalization === false
			&& G.replaygain === 'off'
		) {
			G.novolume = true;
		} else {
			G.novolume = false;
		}
		$( '#novolume' ).prop( 'checked', G.novolume );
		$( '#divdop' ).toggleClass( 'hide', $selected.val().slice( 0, 7 ) === 'bcm2835' );
		$( '#dop' ).prop( 'checked', $selected.data( 'dop' ) );
		$( '#crossfade' ).prop( 'checked', G.crossfade > 0 );
		$( '#setting-crossfade' ).toggleClass( 'hide', G.crossfade === 0 );
		$( '#normalization' ).prop( 'checked', G.normalization );
		$( '#replaygain' ).prop( 'checked', G.replaygain !== 'off' );
		$( '#setting-replaygain' ).toggleClass( 'hide', G.replaygain === 'off' );
		$( '#autoupdate' ).prop( 'checked', G.autoupdate );
		$( '#buffer' ).prop( 'checked', G.buffer > 4096 );
		$( '#setting-buffer' ).toggleClass( 'hide', G.buffer === '' );
		$( '#bufferoutput' ).prop( 'checked', G.bufferoutput > 8192 );
		$( '#setting-bufferoutput' ).toggleClass( 'hide', G.bufferoutput === '' );
		$( '#ffmpeg' ).prop( 'checked', G.ffmpeg );
		$( '#soxr' ).prop( 'checked', G.soxr );
		$( '#setting-soxr' ).toggleClass( 'hide', !G.soxr );
		[ 'aplay', 'amixer', 'mpdconf', 'mpdstatus' ].forEach( function( id ) {
			codeToggle( id, 'status' );
		} );
		resetLocal();
		showContent();
	}, 'json' );
}
refreshData();
//---------------------------------------------------------------------------------------
$( '#audiooutput, #mixertype' ).selectric();
$( '.selectric-input' ).prop( 'readonly', 1 ); // fix - suppress screen keyboard
var setmpdconf = '/srv/http/bash/mpd-conf.sh';
var warning = '<wh><i class="fa fa-warning fa-lg"></i>&ensp;Lower amplifier volume.</wh>'
			 +'<br>(If current level in MPD is not 100%.)'
			 +'<br><br>Signal level will be set to full amplitude to 0dB'
			 +'<br>Too high volume can damage speakers and ears';
$( '#audiooutput' ).on( 'selectric-change', function() {
	var $selected = $( this ).find( ':selected' );
	G.audiooutput = $selected.text();
	G.audioaplayname = $selected.val();
	card = $selected.data( 'card' );
	cmd.amixer = 'amixer -c '+ card;
	var hwmixer = $selected.data( 'hwmixer' );
	notify( 'Audio Output Device', 'Change ...', 'mpd' );
	bash( [ 'audiooutput', G.audioaplayname, card, G.audiooutput, hwmixer ], refreshData );
	$( '#divdop' ).toggleClass( 'hide', G.audioaplayname.slice( 0, 7 ) === 'bcm2835' );
} );
$( '#mixertype' ).on( 'selectric-change', function() {
	var mixertype = $( this ).val();
	if ( mixertype === 'none' ) {
		info( {
			  icon    : 'volume'
			, title   : 'Volume Level'
			, message : warning
			, cancel  : function() {
				$( '#mixertype' )
					.val( $( '#audiooutput option:selected' ).data( 'mixertype' ) )
					.selectric( 'refresh' );
			}
			, ok      : function() {
				setMixerType( mixertype );
			}
		} );
	} else {
		setMixerType( mixertype );
	}
} );
$( '#setting-mixertype' ).click( function() { // hardware mixer
	var $selectedoutput = $( '#audiooutput option:selected' );
	var card = $selectedoutput.data( 'card' );
	var hwmixer = $selectedoutput.data( 'hwmixer' );
	var select = $selectedoutput.data( 'mixermanual' ) ? { 'Auto select': 'auto' } : {};
	bash( [ 'amixer', card ], function( data ) {
		var devices = data.slice( 0, -1 ).split( '\n' );
		devices.forEach( function( val ) {
			select[ val ] = val;
		} );
		info( {
			  icon    : 'volume'
			, title   : 'Hardware Mixer'
			, message : 'Manually select hardware mixer:'
					   +'<br>(Only if current one not working)'
			, selectlabel : 'Device'
			, select  : select
			, checked : hwmixer
			, preshow : function() {
				$( '#infoOk' ).addClass( 'disabled' );
				$( '#infoSelectBox' )
					.selectric()
					.on( 'selectric-change', function() {
						$( '#infoOk' ).toggleClass( 'disabled', $( this ).val() === hwmixer );
					} );
			}
			, ok      : function() {
				var name = $( '#audiooutput option:selected' ).text();
				var mixermanual = $( '#infoSelectBox' ).val();
				var mixerauto = mixermanual === 'auto';
				var mixer = mixerauto ? hwmixer : mixermanual;
				notify( 'Hardware Mixer', 'Change ...', 'mpd' );
				bash( [ 'mixerhw', name, mixer, mixermanual, card ], refreshData );
			}
		} );
	}, 'json' );
} );
$( '#novolume' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( checked ) {
		info( {
			  icon    : 'volume'
			, title   : 'Mixer Control'
			, message : warning
			, ok      : function() {
				G.crossfade === 0;
				G.normalization === false;
				G.replaygain === 'off';
				var name = $( '#audiooutput option:selected' ).text();
				notify( 'No Volume', 'Enable ...', 'mpd' );
				bash( [ 'novolume', name ], refreshData );
			}
		} );
	} else {
		info( {
			  icon    : 'volume'
			, title   : 'Mixer Control'
			, message : 'Enable any volume features - disable <wh>No volume</wh>.'
		} );
		$( this ).prop( 'checked', 1 );
	}
} );
$( '#dop' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	var $selected = $( '#audiooutput option:selected' );
	var name = $selected.text();
	$selected.data( 'dop', 1 );
	notify( 'DSP over PCM', checked, 'mpd' );
	bash( [ 'dop', checked, name ], refreshData );
} );
$( '#crossfade' ).click( function() {
	if ( $( this ).prop( 'checked' ) ) {
		$( '#setting-crossfade' ).click();
	} else {
		notify( 'Crossfade', G.crossfade > 0, 'mpd' );
		bash( [ 'crossfade' ], refreshData );
	}
} );
$( '#setting-crossfade' ).click( function() {
	info( {
		  icon    : 'mpd'
		, title   : 'Crossfade'
		, message : 'Seconds:'
		, radio   : { 1: 1, 2: 2, 3: 3, 4: 4, 5: 5 }
		, preshow : function() {
			$( 'input[name=inforadio]' ).val( [ G.crossfade || 2 ] )
		}
		, cancel    : function() {
			if ( !G.crossfade ) {
				$( '#crossfade' ).prop( 'checked', 0 );
				$( '#setting-crossfade' ).addClass( 'hide' );
			}
		}
		, ok      : function() {
			crossfade = $( 'input[name=inforadio]:checked' ).val();
			if ( crossfade !== G.crossfade ) {
				G.crossfade = crossfade;
				notify( 'Crossfade', 'Change ...', 'mpd' );
				bash( [ 'crossfade ', G.crossfade ], refreshData );
			}
		}
	} );
} );
$( '#normalization' ).click( function() {
	G.normalization = $( this ).prop( 'checked' );
	notify( 'Normalization', G.normalization, 'mpd' );
	bash( [ 'normalization', G.normalization ], refreshData );
} );
$( '#replaygain' ).click( function() {
	if ( $( this ).prop( 'checked' ) ) {
		$( '#setting-replaygain' ).click();
	} else {
		notify( 'Replay Gain', G.replaygain !== 'off', 'mpd' );
		bash( [ 'replaygain' ], refreshData );
	}
} );
$( '#setting-replaygain' ).click( function() {
	info( {
		  icon      : 'mpd'
		, title     : 'Replay Gain'
		, radio     : { Auto: 'auto', Album: 'album', Track: 'track' }
		, preshow : function() {
			var checked = G.replaygain === 'off' ? 'auto' : G.replaygain;
			$( 'input[name=inforadio]' ).val( [ checked ] )
		}
		, cancel    : function() {
			if ( G.replaygain === 'off' ) {
				$( '#replaygain' ).prop( 'checked', 0 );
				$( '#setting-replaygain' ).addClass( 'hide' );
			}
		}
		, ok        : function() {
			replaygain = $( 'input[name=inforadio]:checked' ).val();
			if ( replaygain !== G.replaygain ) {
				G.replaygain = replaygain;
				notify( 'Replay Gain', 'Change ...', 'mpd' );
				bash( [ 'replaygain', G.replaygain ], refreshData );
			}
		}
	} );
} );
$( '#autoupdate' ).click( function() {
	G.autoupdate = $( this ).prop( 'checked' );
	notify( 'Auto Update', G.autoupdate, 'mpd' );
	bash( [ 'autoupdate', G.autoupdate ], refreshData );
} );
$( '#buffer' ).click( function() {
	if ( $( this ).prop( 'checked' ) ) {
		$( '#setting-buffer' ).click();
	} else {
		notify( 'Custom Buffer', 'Disable ...', 'mpd' );
		bash( [ 'buffer' ], refreshData );
	}
} );
$( '#setting-buffer' ).click( function() {
	info( {
		  icon      : 'mpd'
		, title     : 'Audio Buffer'
		, message   : '<code>audio_buffer_size</code> (default: 4096)'
		, textlabel : 'Size <gr>(kB)</gr>'
		, textvalue : G.buffer || 4096
		, cancel    : function() {
			if ( !G.buffer ) {
				$( '#buffer' ).prop( 'checked', 0 );
				$( '#setting-buffer' ).addClass( 'hide' );
			}
		}
		, ok        : function() {
			var buffer = $( '#infoTextBox' ).val().replace( /\D/g, '' );
			if ( buffer < 4097 ) {
				info( {
					  icon    : 'mpd'
					, title   : 'Audio Buffer'
					, message : '<i class="fa fa-warning fa-lg"></i> Warning<br>'
							   +'<br>Audio buffer must be greater than <wh>4096 kB</wh>.'
				} );
				if ( !G.buffer ) $( '#buffer' ).prop( 'checked', 0 );
			} else if ( buffer !== G.buffer ) {
				G.buffer = buffer;
				notify( 'Audio Buffer', 'Change ...', 'mpd' );
				bash( [ 'buffer', G.buffer ], refreshData );
			}
		}
	} );
} );
$( '#bufferoutput' ).click( function() {
	if ( $( this ).prop( 'checked' ) ) {
		$( '#setting-bufferoutput' ).click();
	} else {
		notify( 'Custom Output Buffer', 'Disable ...', 'mpd' );
		bash( [ 'bufferoutput' ], refreshData );
	}
} );
$( '#setting-bufferoutput' ).click( function() {
	info( {
		  icon      : 'mpd'
		, title     : 'Output Buffer'
		, message   : '<code>max_output_buffer_size</code> (default: 8192)'
		, textlabel : 'Size <gr>(kB)</gr>'
		, textvalue : G.bufferoutput || 8192
		, cancel    : function() {
			if ( !G.buffer ) {
				$( '#bufferoutput' ).prop( 'checked', 0 );
				$( '#setting-bufferoutput' ).addClass( 'hide' );
			}
		}
		, ok        : function() {
			var buffer = $( '#infoTextBox' ).val().replace( /\D/g, '' );
			if ( buffer < 8192 ) {
				info( {
					  icon    : 'mpd'
					, title   : 'Output Buffer'
					, message : '<i class="fa fa-warning fa-lg"></i> Warning<br>'
							   +'<br>Output buffer must be greater than <wh>8192 kB</wh>.'
				} );
				if ( !G.bufferoutput ) $( '#bufferoutput' ).prop( 'checked', 0 );
			} else if ( buffer !== G.bufferoutput ) {
				G.bufferoutput = buffer;
				notify( 'Output Buffer', 'Change ...', 'mpd' );
				bash( [ 'bufferoutput', G.bufferoutput ], refreshData );
			}
		}
	} );
} );
$( '#ffmpeg' ).click( function() {
	G.ffmpeg = $( this ).prop( 'checked' );
	notify( 'FFmpeg Decoder', G.ffmpeg, 'mpd' );
	bash( [ 'ffmpeg', G.ffmpeg ], refreshData );
} );
$( '#soxr' ).click( function() {
	G.soxr = $( this ).prop( 'checked' );
	notify( 'Custom SoX Resampler', G.soxr, 'mpd' );
	bash( [ 'soxr', G.soxr ], refreshData );
} );
$( '#setting-soxr' ).click( function() {
	info( {
		  icon       : 'mpd'
		, title      : 'Custom SoX Resampler'
		, textlabel  : [
			  'Threads'
			, 'Precision <gr>(bit)</gr>'
			, 'Phase Response'
			, 'Passband End <gr>(%)</gr>'
			, 'Stopband Begin <gr>(%)</gr>'
			, 'Attenuation  <gr>(dB)</gr>'
			, 'Flags'
		]
		, textvalue  : G.soxrset.split( ' ' )
		, textsuffix : [ 1, 20, 50, 95, 100, 0, 0 ]
		, boxwidth   : 80
		, footer     : '(default)&emsp;'
		, footalign  : 'right'
		, ok         : function() {
			var args = [ 'soxrset' ];
			for ( i = 0; i < 7; i++ ) {
				if ( i === 0 ) i = '';
				args.push( Number( $( '#infoTextBox'+ i ).val() ) );
			}
			if ( args.toString().replace( /,/g, ' ' ) === 'soxrset '+ G.soxrset ) return
			
			bash( args, refreshData );
		}
	} );
} );
$( '#mpdrestart' ).click( function() {
	$this = $( this );
	info( {
		  icon    : 'mpd'
		, title   : 'MPD'
		, message : 'Restart MPD?'
		, ok      : function() {
			notify( 'MPD', 'Restart ...', 'mpd' );
			bash( '/srv/http/bash/mpd-conf.sh', refreshData );
		}
	} );
} );

} ); // document ready end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
