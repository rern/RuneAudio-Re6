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
	var cmd = [];
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
		if ( G.manualconf ) {
			bash( 'cat /etc/mpd.conf', function( data ) {
				$( '.container' ).css( 'padding-bottom', '30px' );
				$( '#manualconf' ).prop( 'checked', 1 );
				$( '#divmain, #mpdconf .fa-code' ).addClass( 'hide' );
				$( '#setting-manualconf, #codemanualconf' ).removeClass( 'hide' );
				$( '#codemanualconf' ).text( data );
				codeToggle( 'mpd', 'status' );
				showContent();
			} );
			return
			
		} else {
			$( '.container' ).css( 'padding-bottom', '' );
			$( '#manualconf' ).prop( 'checked', 0 );
			$( '#divmain, #mpdconf .fa-code' ).removeClass( 'hide' );
			$( '#setting-manualconf, #codemanualconf' ).addClass( 'hide' );
			$( '#codemanualconf' ).empty();
		}
		var htmldevices = '';
		$.each( G.devices, function() {
			htmldevices += '<option '
				+'value="'+ this.aplayname +'" '
				+'data-card="'+ this.card +'" '
				+'data-device="'+ this.device +'" '
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
		$( '#ffmpeg' ).prop( 'checked', G.ffmpeg );
		$( '#buffer' ).prop( 'checked', G.buffer > 4096 );
		$( '#setting-buffer' ).toggleClass( 'hide', G.buffer === '' );
		$( '#bufferoutput' ).prop( 'checked', G.bufferoutput > 8192 );
		$( '#setting-bufferoutput' ).toggleClass( 'hide', G.bufferoutput === '' );
		var format = $selected.data( 'format' ) !== '';
		$( '#custom' ).prop( 'checked', G.custom );
		$( '#setting-custom' ).toggleClass( 'hide', !G.custom );
		$( '#soxr' ).prop( 'checked', G.soxr );
		$( '#setting-soxr' ).toggleClass( 'hide', !G.soxr );
		[ 'aplay', 'amixer', 'mpd', 'mpdconf' ].forEach( function( id ) {
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
	bash( [ 'audiooutput', G.audioaplayname, card, G.audiooutput, hwmixer ] );
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
			  icon        : 'volume'
			, title       : 'Hardware Mixer'
			, message     : 'Manually select hardware mixer:'
						   +'<br>(Only if current one not working)'
			, selectlabel : 'Device'
			, select      : select
			, checked     : hwmixer
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
				bash( [ 'novolume', name ] );
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
	notify( 'DSP over PCM', checked, 'mpd' );
	bash( [ 'dop', checked, name ] );
} );
$( '#crossfade' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( G.crossfadeset ) {
		notify( 'Crossfade', 'Disable ...', 'mpd' );
		bash( [ 'crossfade', 0 ] );
	} else {
		$( '#setting-crossfade' ).click();
	}
} );
$( '#setting-crossfade' ).click( function() {
	info( {
		  icon    : 'mpd'
		, title   : 'Crossfade'
		, message : 'Seconds:'
		, radio   : { 1: 1, 2: 2, 3: 3, 4: 4, 5: 5 }
		, checked : G.crossfadeset || 2
		, cancel    : function() {
			if ( !G.crossfadeset ) $( '#crossfade' ).prop( 'checked', 0 );
		}
		, ok      : function() {
			crossfadeset = $( 'input[name=inforadio]:checked' ).val();
			if ( crossfadeset !== G.crossfadeset ) {
				notify( 'Crossfade', 'Change ...', 'mpd' );
				bash( [ 'crossfadeset', crossfadeset ] );
			}
		}
	} );
} );
$( '#normalization' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	notify( 'Normalization', checked, 'mpd' );
	bash( [ 'normalization', checked ] );
} );
$( '#replaygain' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( G.replaygainset ) {
		notify( 'Replay Gain', 'Disable ...', 'mpd' );
		bash( [ 'replaygain' ] );
	} else {
		$( '#setting-replaygain' ).click();
	}
} );
$( '#setting-replaygain' ).click( function() {
	info( {
		  icon    : 'mpd'
		, title   : 'Replay Gain'
		, radio   : { Auto: 'auto', Album: 'album', Track: 'track' }
		, checked : G.replaygainset || 'auto'
		, cancel  : function() {
			if ( !G.replaygainset ) $( '#replaygain' ).prop( 'checked', 0 );
		}
		, ok      : function() {
			replaygainset = $( 'input[name=inforadio]:checked' ).val();
			if ( replaygainset !== G.replaygainset ) {
				notify( 'Replay Gain', 'Change ...', 'mpd' );
				bash( [ 'replaygainset', replaygainset ] );
			}
		}
	} );
} );
$( '#autoupdate' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	notify( 'Auto Update', checked, 'mpd' );
	bash( [ 'autoupdate', checked ] );
} );
$( '#ffmpeg' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	notify( 'FFmpeg Decoder', checked, 'mpd' );
	bash( [ 'ffmpeg', checked ] );
} );
$( '#buffer' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( G.bufferset ) {
		notify( 'Custom Audio Buffer', 'Disable ...', 'mpd' );
		bash( [ 'buffer', 0 ] );
	} else {
		$( '#setting-buffer' ).click();
	}
} );
$( '#setting-buffer' ).click( function() {
	info( {
		  icon      : 'mpd'
		, title     : 'Custom Audio Buffer'
		, message   : '<code>audio_buffer_size</code> (default: 4096)'
		, textlabel : 'Size <gr>(kB)</gr>'
		, textvalue : G.bufferset || 4096
		, cancel    : function() {
			if ( !G.bufferset ) $( '#buffer' ).prop( 'checked', 0 );
		}
		, ok        : function() {
			var bufferset = $( '#infoTextBox' ).val().replace( /\D/g, '' );
			if ( bufferset < 4097 ) {
				info( {
					  icon    : 'mpd'
					, title   : 'Audio Buffer'
					, message : '<i class="fa fa-warning fa-lg wh"></i> Warning<br>'
							   +'<br>Audio buffer must be greater than <wh>4096 kB</wh>.'
					, ok      : function() {
						$( '#setting-buffer' ).click();
					}
				} );
				if ( !G.bufferset ) $( '#buffer' ).prop( 'checked', 0 );
			} else if ( bufferset !== G.bufferset ) {
				notify( 'Audio Buffer', 'Change ...', 'mpd' );
				bash( [ 'bufferset', G.bufferset ] );
			}
		}
	} );
} );
$( '#bufferoutput' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( G.bufferoutputset ) {
		notify( 'Custom Output Buffer', 'Disable ...', 'mpd' );
		bash( [ 'bufferoutput' ] );
	} else {
		$( '#setting-bufferoutput' ).click();
	}
} );
$( '#setting-bufferoutput' ).click( function() {
	info( {
		  icon      : 'mpd'
		, title     : 'Custom Output Buffer'
		, message   : '<code>max_output_buffer_size</code> (default: 8192)'
		, textlabel : 'Size <gr>(kB)</gr>'
		, textvalue : G.bufferoutputset || 8192
		, cancel    : function() {
			if ( !G.bufferoutputset ) $( '#bufferoutput' ).prop( 'checked', 0 );
		}
		, ok        : function() {
			var bufferoutputset = $( '#infoTextBox' ).val().replace( /\D/g, '' );
			if ( bufferoutputset < 8192 ) {
				info( {
					  icon    : 'mpd'
					, title   : 'Custom Output Buffer'
					, message : '<i class="fa fa-warning fa-lg wh"></i> Warning<br>'
							   +'<br>Output buffer must be greater than <wh>8192 kB</wh>.'
					, ok      : function() {
						$( '#setting-bufferoutput' ).click();
					}
				} );
				if ( !G.bufferoutputset ) $( '#bufferoutput' ).prop( 'checked', 0 );
			} else if ( bufferoutputset !== G.bufferoutputset ) {
				notify( 'Output Buffer', 'Change ...', 'mpd' );
				bash( [ 'bufferoutputset', bufferoutputset ] );
			}
		}
	} );
} );
$( '#filetype' ).click( function() {
	$( '#divfiletype' ).toggleClass( 'hide' );
} );
$( '#soxr' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( G.soxrset ) {
		notify( 'Custom SoX Resampler', checked, 'mpd' );
		bash( [ 'soxr', checked ] );
	} else {
		$( '#setting-soxr' ).click();
	}
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
	info( {
		  icon        : 'mpd'
		, title       : 'Custom SoX Resampler'
		, content     : soxrinfo
		, nofocus     : 1
		, preshow     : function() {
			var soxrset = G.soxrset ? G.soxrset.split( ' ' ) : defaultval;
			$( '#infoSelectBox option[value='+ soxrset[ 0 ] +']' ).prop( 'selected', 1 );
			$( '#infoSelectBox1 option[value='+ soxrset[ 5 ] +']' ).prop( 'selected', 1 );
			for ( i = 1; i < 5; i++ ) {
				$( '#infoTextBox'+ i ).val( soxrset[ i ] );
			}
			setTimeout( function() {
			$( '#extra .selectric, #extra .selectric-wrapper' ).css( 'width', '185px' );
			$( '#extra .selectric-items' ).css( 'min-width', '185px' );
			}, 0 );
			$( '#infoButton' )
				.off( 'click' )
				.click( function() {
					soxr = defaultval;
					for ( i = 1; i < 5; i++ ) {
						$( '#infoTextBox'+ i ).val( soxrset[ i ] );
					}
				} );
		}
		, boxwidth    : 70
		, buttonlabel : '<i class="fa fa-undo"></i>Default'
		, buttoncolor : '#de810e'
		, button      : 1
		, buttonwidth : 1
		, cancel      : function() {
			if ( !G.soxrset ) $( '#soxr' ).prop( 'checked', 0 );
		}
		, ok          : function() {
			var args = [ $( '#infoSelectBox' ).val() ];
			for ( i = 1; i < 5; i++ ) {
				args.push( Number( $( '#infoTextBox'+ i ).val() ) );
			}
			args.push( $( '#infoSelectBox1' ).val() );
			if ( args.toString().replace( /,/g, ' ' ) === G.soxrset ) return
			
			var errors = '';
			if ( args[ 1 ] < 0 || args[ 1 ] > 100 ) errors += '<br><w>Phase Response</w> is not 1-100';
			if ( args[ 2 ] < 0 || args[ 2 ] > 100 ) errors += '<br><w>Passband End</w> is not 1-100<br>';
			if ( args[ 3 ] < 100 || args[ 3 ] > 150 ) errors += '<br><w>Stopband Begin</w> is not 100-150';
			if ( args[ 4 ] < 0 || args[ 4 ] > 30 ) errors += '<br><w>Attenuation</w> is not 0-30<br>';
			if ( errors ) {
				info( {
					  icon    : 'mpd'
					, title   : 'Custom SoX Resampler'
					, message : '<i class="fa fa-warning fa-lg wh"></i> Warning<br>'
							   + errors
					, ok      : function() {
						$( '#setting-soxr' ).click();
					}
				} );
				return
			}
			
			args.unshift( 'soxrset' );
			notify( 'Custom SoX Resampler', 'Change ...', 'mpd' );
			bash( args );
		}
	} );
} );
$( '#custom' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( G.customset ) {
		notify( "User's Custom Settings", checked, 'mpd' );
		bash( [ 'custom', checked ] );
	} else {
		$( '#setting-custom' ).click();
	}
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
	info( {
		  icon     : 'mpd'
		, title    : "User's Custom Settings"
		, content  : custominfo
		, msgalign : 'left'
		, boxwidth : 'max'
		, preshow  : function() {
			$( '#global' ).val( G.customglobal );
			$( '#output' ).val( G.customoutput );
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
			if ( !G.customset ) $( '#custom' ).prop( 'checked', 0 );
		}
		, ok       : function() {
			var customglobal = lines2line( $( '#global' ).val() );
			var customoutput = lines2line( $( '#output' ).val() );
			if ( customglobal !== G.customglobal || customoutput !== G.customoutput ) {
				var file = '/srv/http/data/system/mpd-custom';
				notify( "User's Custom Settings", 'Change ...', 'mpd' );
				bash( [ 'customset', customglobal, customoutput ] );
			}
		}
	} );
} );
$( '#setting-manualconf' ).click( function() {
	notify( 'Manual Configure', 'Change ...', 'mpd' );
	bash( [ 'manualconfsave', $( '#codemanualconf' ).val() ] );
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
$( '#manualconf' ).click( function() {
	if ( $( this ).prop( 'checked' ) ) {
		info( {
			  icon    : 'mpd'
			, title   : 'Manual Mode'
			, message : 'Once enabled, any further changes must be reconfigured manually.'
						+'<br><br>Continue?'
			, ok      : function() {
				bash( [ 'manualconf', true ] );
			}
		} );
	} else {
		bash( [ 'manualconf', false ] );
	}
} );

} ); // document ready end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
