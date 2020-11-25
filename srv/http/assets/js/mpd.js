$( function() { // document ready start >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

function lines2line( lines ) {
	var val = '';
	var lines = lines.split( '\n' ).filter( e => e );
	lines.forEach( function( el ) {
		val += '^'+ el;
	} );
	return val.substring( 1 );
}
function setMixerType( mixertype ) {
	var $output = $( '#audiooutput option:selected' );
	var name = $output.text();
	if ( mixertype === 'none' ) {
		var card = $output.data( 'card' );
		var hwmixer = $output.data( 'hwmixer' );
	} else {
		var card = '';
		var hwmixer = '';
	}
	notify( 'Mixer Control', 'Change ...', 'mpd' );
	bash( [ 'mixerset', mixertype, name, card, hwmixer ] );
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
						  +'data-format="'+ this.format +'"'
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
		var $selected = $( '#audiooutput option:selected' );
		if ( $selected.data( 'hwmixer' ) ) {
			var mixerhtml =  '<option value="none">Disable</option>'
							+'<option value="hardware">DAC hardware</option>'
							+'<option value="software">MPD software</option>';
			$( '#hwmixertxt' ).show();
		} else {
			var mixerhtml =  '<option value="none">Disable</option>'
							+'<option value="software">MPD software</option>';
			$( '#hwmixertxt' ).hide();
		}
		var mixertype = $selected.data( 'mixertype' );
		$( '#mixertype' ).html( mixerhtml ).val( mixertype );
		$( '#audiooutput, #mixertype' ).selectric( 'refresh' );
		if ( $( '#mixertype' ).val() === 'hardware' && $selected.data( 'mixercount' ) > 1 ) {
			$( '.hwmixer' ).removeClass( 'hide' );
		} else {
			$( '.hwmixer' ).addClass( 'hide' );
		}
		$( '#divmixer' ).toggleClass( 'hide', $selected.data( 'hwmixer' ) === '' );
		if ( mixertype === 'none' && !G.crossfade && !G.normalization && !G.replaygain ) {
			G.novolume = true;
		} else {
			G.novolume = false;
		}
		$( '#novolume' ).prop( 'checked', G.novolume );
		$( '#divdop' ).toggleClass( 'hide', $selected.val().slice( 0, 7 ) === 'bcm2835' );
		$( '#dop' ).prop( 'checked', $selected.data( 'dop' ) );
		$( '#crossfade' ).prop( 'checked', G.crossfade );
		$( '#setting-crossfade' ).toggleClass( 'hide', !G.crossfade );
		$( '#normalization' ).prop( 'checked', G.normalization );
		$( '#replaygain' ).prop( 'checked', G.replaygain );
		$( '#setting-replaygain' ).toggleClass( 'hide', !G.replaygain );
		$( '#autoupdate' ).prop( 'checked', G.autoupdate );
		$( '#ffmpeg' ).prop( 'checked', G.ffmpeg );
		$( '#buffer' ).prop( 'checked', G.buffer );
		$( '#setting-buffer' ).toggleClass( 'hide', !G.buffer );
		$( '#bufferoutput' ).prop( 'checked', G.bufferoutput );
		$( '#setting-bufferoutput' ).toggleClass( 'hide', !G.bufferoutput );
		var format = $selected.data( 'format' ) !== '';
		$( '#custom' ).prop( 'checked', G.custom );
		$( '#setting-custom' ).toggleClass( 'hide', !G.custom );
		$( '#soxr' ).prop( 'checked', G.soxr );
		$( '#setting-soxr' ).toggleClass( 'hide', !G.soxr );
		[ 'aplay', 'amixer', 'crossfade', 'mpd', 'mpdconf' ].forEach( function( id ) {
			codeToggle( id, 'status' );
		} );
		resetLocal();
		showContent();
	}, 'json' );
}
refreshData();
//---------------------------------------------------------------------------------------
$( '.enable' ).click( function() {
	var idname = {
		  buffer       : 'Custom Audio Buffer'
		, bufferoutput : 'Custom Output Buffer'
		, crossfade    : 'Crossfade'
		, custom       : "User's Custom Settings"
		, replaygain   : 'Replay Gain'
		, soxr         : 'SoXR Custom Settings'
	}
	var checked = $( this ).prop( 'checked' );
	var id = this.id;
	if ( G[ id +'set' ] ) {
		notify( idname[ id ], checked, 'mpd' );
		checked ? bash( [ id +'set', G[ id +'val' ] ] ) : bash( [ id +'disable' ] );
	} else {
		$( '#setting-'+ id ).click();
	}
} );
$( '.enablenoset' ).click( function() {
	var idname = {
		  autoupdate    : 'Auto Update'
		, ffmpeg        : 'FFmpeg Decoder'
		, normalization : 'Normalization'
	}
	var checked = $( this ).prop( 'checked' );
	var id = this.id;
	notify( idname[ id ], checked, 'mpd' );
	bash( [ id, checked ] );
} );

$( '#audiooutput, #mixertype' ).selectric();
$( '.selectric-input' ).prop( 'readonly', 1 ); // fix - suppress screen keyboard
var setmpdconf = '/srv/http/bash/mpd-conf.sh';
var warning = '<wh><i class="fa fa-warning fa-lg"></i>&ensp;Lower amplifier volume.</wh>'
			 +'<br>(If current level in MPD is not 100%.)'
			 +'<br><br>Signal level will be set to full amplitude to 0dB'
			 +'<br>Too high volume can damage speakers and ears';
$( '#audiooutput' ).on( 'selectric-change', function() {
	var $selected = $( this ).find( ':selected' );
	var output = $selected.text();
	var aplayname = $selected.val();
	var card = $selected.data( 'card' );
	var hwmixer = $selected.data( 'hwmixer' );
	notify( 'Audio Output Device', 'Change ...', 'mpd' );
	aplayname = output !== G.usbdac ? aplayname : '';
	bash( [ 'audiooutput', aplayname, card, output, hwmixer ] );
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
		var devices = data.split( '\n' );
		devices.forEach( function( val ) {
			select[ val ] = val;
		} );
		info( {
			  icon        : 'volume'
			, title       : 'Hardware Mixer'
			, message     : 'Manually select hardware mixer:'
						   +'<br>(Only if current one not working)'
			, selectlabel : 'Device'
			, select      : select
			, checked     : hwmixer
			, boxwidth    : 280
			, preshow     : function() {
				$( '#infoOk' ).addClass( 'disabled' );
				$( '#infoSelectBox' ).on( 'selectric-change', function() {
					$( '#infoOk' ).toggleClass( 'disabled', $( this ).val() === hwmixer );
				} );
			}
			, ok          : function() {
				var name = $( '#audiooutput option:selected' ).text();
				var mixermanual = $( '#infoSelectBox' ).val();
				var mixerauto = mixermanual === 'auto';
				var mixer = mixerauto ? hwmixer : mixermanual;
				notify( 'Hardware Mixer', 'Change ...', 'mpd' );
				bash( [ 'mixerhw', name, mixer, mixermanual, card ] );
			}
		} );
	} );
} );
$( '#novolume' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( checked ) {
		info( {
			  icon    : 'volume'
			, title   : 'No Volume'
			, message : warning
			, ok      : function() {
				notify( 'No Volume', 'Enable ...', 'mpd' );
				bash( [ 'novolume', $( '#audiooutput option:selected' ).text() ] );
			}
		} );
	} else {
		info( {
			  icon    : 'volume'
			, title   : 'No Volume'
			, message : '<wh>No volume</wh> will be disabled on:'
						+'<br>&emsp; &bull; Select a Mixer Control'
						+'<br>&emsp; &bull; Enable any Volume options'
			, msgalign : 'left'
		} );
		$( this ).prop( 'checked', 1 );
	}
} );
$( '#dop' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	notify( 'DSP over PCM', checked, 'mpd' );
	bash( [ 'dop', checked, $( '#audiooutput option:selected' ).text() ] );
} );
$( '#setting-crossfade' ).click( function() {
	info( {
		  icon    : 'mpd'
		, title   : 'Crossfade'
		, message : 'Seconds:'
		, radio   : { 1: 1, 2: 2, 3: 3, 4: 4, 5: 5 }
		, checked : G.crossfadeval || 1
		, cancel    : function() {
			if ( !G.crossfade ) $( '#crossfade' ).prop( 'checked', 0 );
		}
		, ok      : function() {
			crossfadeval = $( 'input[name=inforadio]:checked' ).val();
			if ( !G.crossfade || crossfadeval !== G.crossfadeval ) {
				notify( 'Crossfade', 'Change ...', 'mpd' );
				bash( [ 'crossfadeset', crossfadeval ] );
			} else {
				if ( !G.crossfade ) $( '#crossfade' ).prop( 'checked', 0 );
			}
		}
	} );
} );
$( '#setting-replaygain' ).click( function() {
	info( {
		  icon    : 'mpd'
		, title   : 'Replay Gain'
		, radio   : { Auto: 'auto', Album: 'album', Track: 'track' }
		, checked : G.replaygainval || 'auto'
		, cancel  : function() {
			if ( !G.replaygain ) $( '#replaygain' ).prop( 'checked', 0 );
		}
		, ok      : function() {
			replaygainval = $( 'input[name=inforadio]:checked' ).val();
			if ( !G.replaygain || replaygainval !== G.replaygainval ) {
				notify( 'Replay Gain', 'Change ...', 'mpd' );
				bash( [ 'replaygainset', replaygainval ] );
			} else {
				if ( !G.replaygain ) $( '#replaygain' ).prop( 'checked', 0 );
			}
		}
	} );
} );
$( '#filetype' ).click( function() {
	$( '#divfiletype' ).toggleClass( 'hide' );
} );
$( '#setting-buffer' ).click( function() {
	info( {
		  icon      : 'mpd'
		, title     : 'Custom Audio Buffer'
		, message   : '<code>audio_buffer_size</code> (default: 4096)'
		, textlabel : 'Size <gr>(kB)</gr>'
		, textvalue : G.bufferval || 4096
		, cancel    : function() {
			if ( !G.buffer ) $( '#buffer' ).prop( 'checked', 0 );
		}
		, ok        : function() {
			var bufferval = $( '#infoTextBox' ).val().replace( /\D/g, '' );
			if ( !G.buffer || bufferval !== G.bufferval ) {
				notify( 'Audio Buffer', G.bufferset ? 'Change ...' : 'Disable ...', 'mpd' );
				bash( [ 'bufferset', bufferval ] );
			} else {
				if ( !G.buffer ) $( '#buffer' ).prop( 'checked', 0 );
			}
		}
	} );
} );
$( '#setting-bufferoutput' ).click( function() {
	info( {
		  icon      : 'mpd'
		, title     : 'Custom Output Buffer'
		, message   : '<code>max_output_buffer_size</code> (default: 8192)'
		, textlabel : 'Size <gr>(kB)</gr>'
		, textvalue : G.bufferoutputval || 8192
		, cancel    : function() {
			if ( !G.bufferoutput ) $( '#bufferoutput' ).prop( 'checked', 0 );
		}
		, ok        : function() {
			var bufferoutputval = $( '#infoTextBox' ).val().replace( /\D/g, '' );
			if ( !G.bufferoutput || bufferoutputval !== G.bufferoutputval ) {
				notify( 'Output Buffer', 'Change ...', 'mpd' );
				bash( [ 'bufferoutputset', bufferoutputval ] );
			} else {
				if ( !G.bufferoutput ) $( '#bufferoutput' ).prop( 'checked', 0 );
			}
		}
	} );
} );
var soxrinfo = heredoc( function() { /*
	<div id="infoText" class="infocontent">
		<div class="infotextlabel">
			<a class="infolabel">Precision <gr>(bit)</gr></a>
			<a class="infolabel">Phase Response</a>
			<a class="infolabel">Passband End <gr>(%)</gr></a>
			<a class="infolabel">Stopband Begin <gr>(%)</gr></a>
			<a class="infolabel">Attenuation <gr>(dB)</gr></a>
		</div>
		<div class="infotextbox">
			<select class="infohtml" id="infoSelectBox">
				<option value="16">16</option>
				<option value="20">20</option>
				<option value="24">24</option>
				<option value="28">28</option>
				<option value="32">32</option>
			</select>
			<input type="text" class="infoinput input" id="infoTextBox1">
			<input type="text" class="infoinput input" id="infoTextBox2">
			<input type="text" class="infoinput input" id="infoTextBox3">
			<input type="text" class="infoinput input" id="infoTextBox4">
		</div>
		<div id="infotextsuffix">
			<gr>&nbsp;</gr>
			<gr>0-100</gr>
			<gr>0-100</gr>
			<gr>100-150<px30/></gr>
			<gr>0-30</gr>
		</div>
		<div id="extra">
			<div class="infotextlabel">
				<a class="infolabel"><px50/> Extra Settings</a>
			</div>
			<div class="infotextbox">
				<select class="infohtml" id="infoSelectBox1">
					<option value="0">0 - Rolloff - Small</option>
					<option value="1">1 - Rolloff - Medium</option>
					<option value="2">2 - Rolloff - None</option>
					<option value="8">8 - High precision</option>
					<option value="16">16 - Double precision</option>
					<option value="32">32 - Variable rate</option>
				</select>
			</div>
		</div>
	</div>
*/ } );
$( '#setting-soxr' ).click( function() {
	var defaultval = [ 20, 50, 91.3, 100, 0, 0, ];
	var soxrval;
	info( {
		  icon          : 'mpd'
		, title         : 'SoXR Custom Settings'
		, content       : soxrinfo
		, nofocus       : 1
		, preshow       : function() {
			var val = G.soxrval ? G.soxrval.split( ' ' ) : defaultval;
			$( '#infoSelectBox option[value='+ val[ 0 ] +']' ).prop( 'selected', 1 );
			$( '#infoSelectBox1 option[value='+ val[ 5 ] +']' ).prop( 'selected', 1 );
			for ( i = 1; i < 5; i++ ) {
				$( '#infoTextBox'+ i ).val( val[ i ] );
			}
			setTimeout( function() {
				$( '#extra .selectric, #extra .selectric-wrapper' ).css( 'width', '185px' );
				$( '#extra .selectric-items' ).css( 'min-width', '185px' );
			}, 30 );
			if ( G.soxr ) {
				$( '#infoOk' ).addClass( 'disabled' );
				$( '.infoinput' ).keyup( function() {
					soxrval = $( '#infoSelectBox' ).val();
					for ( i = 1; i < 5; i++ ) soxrval += ' '+ $( '#infoTextBox'+ i ).val();
					soxrval += ' '+ $( '#infoSelectBox1' ).val();
					var v = soxrval.split( ' ' );
					var errors = false;
					if (   ( v[ 1 ] < 0 || v[ 1 ] > 100 )
						|| ( v[ 2 ] < 0 || v[ 2 ] > 100 )
						|| ( v[ 3 ] < 100 || v[ 3 ] > 150 )
						|| ( v[ 4 ] < 0 || v[ 4 ] > 30 )
					) errors = true;
					$( '#infoOk' ).toggleClass( 'disabled', soxrval === G.soxrval || errors );
				} );
			}
		}
		, boxwidth      : 70
		, buttonlabel   : '<i class="fa fa-undo"></i>Default'
		, buttoncolor   : '#de810e'
		, button        : function() {
			for ( i = 1; i < 5; i++ ) {
				$( '#infoTextBox'+ i ).val( defaultval[ i ] );
			}
		}
		, buttonnoreset : 1
		, buttonwidth   : 1
		, cancel        : function() {
			if ( !G.soxr ) $( '#soxr' ).prop( 'checked', 0 );
		}
		, ok            : function() {
			notify( 'SoXR Custom Settings', 'Change ...', 'mpd' );
			bash( [ 'soxrset', soxrval ] );
		}
	} );
} );
var custominfo = heredoc( function() { /*
	<p class="infomessage msg">
			<code>/etc/mpd.conf</code>
		<br>...
		<br>user<px style="width: 153px"></px>"mpd"
	</p>
	<div class="infotextbox">
		<textarea class="infoinput" id="global" spellcheck="false"></textarea>
	</div>
	<p class="infomessage msg">
			...
		<br>
		<br>audio_output {
		<br><px30/>...
		<br><px30/>mixer_device<px style="width: 24px"></px>"hw:N"
	</p>
	<div class="infotextbox">
		<textarea class="infoinput" id="output" spellcheck="false"></textarea>
	</div>
	<p class="infomessage msg">
		}
	</p>
*/ } );
$( '#setting-custom' ).click( function() {
	var valglobal, valoutput;
	var output = $( '#audiooutput option:selected' ).text();
	info( {
		  icon     : 'mpd'
		, title    : "User's Custom Settings"
		, content  : custominfo
		, msgalign : 'left'
		, boxwidth : 'max'
		, preshow  : function() {
			bash( [ 'customgetglobal' ], function( data ) { // get directly to keep white spaces
				valglobal = data || '';
				bash( [ 'customgetoutput', output ], function( data ) {
					valoutput = data || '';
					$( '#global' ).val( valglobal );
					$( '#output' ).val( valoutput );
				} );
			} );
			$( '.msg' ).css( {
				  width          : '100%'
				, margin         : 0
				, 'text-align'   : 'left'
				, 'padding-left' : '35px'
			} );
			$( '.msg, #global, #output' ).css( 'font-family', 'Inconsolata' );
			$( '#output' ).css( 'padding-left', '39px' )
		}
		, cancel   : function() {
			if ( !G.custom ) $( '#custom' ).prop( 'checked', 0 );
		}
		, ok       : function() {
			var customglobal = lines2line( $( '#global' ).val() );
			var customoutput = lines2line( $( '#output' ).val() );
			if ( !G.custom || customglobal !== valglobal || customoutput !== valoutput ) {
				var file = '/srv/http/data/system/mpd-custom';
				notify( "User's Custom Settings", 'Change ...', 'mpd' );
				bash( [ 'customset', customglobal, customoutput, output ] );
			} else {
				if ( !G.custom ) $( '#custom' ).prop( 'checked', 0 );
			}
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
			bash( [ 'restart' ] );
		}
	} );
} );

} ); // document ready end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
