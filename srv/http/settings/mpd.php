<div>
<heading>Audio Output<?=$help?></heading>
<div class="col-l control-label">Device</div>
<div class="col-r">
	<select id="audiooutput" data-style="btn-default btn-lg"></select>
</div>
<div class="col-l control-label">Mixer Control</div>
<div class="col-r">
	<select id="mixertype" data-style="btn-default btn-lg"></select>
	<i id="setting-mixertype" class="settingedit fa fa-gear hwmixer"></i><br>
	<span class="hwmixer"><span class="help-block hide"><i class="fa fa-gear"></i>&ensp;Manually select hardware mixer only if the current one is not working.</span></span>
	<span class="help-block hide">Set volume/mixer control for each device.
		<br>Disable: best sound quality. <span id="hwmixertxt">(DAC hardware volume will be reset to 0dB.)
		<br>DAC hardware: good and convenient.</span>
		<br>MPD software: depends on users preferences.
	</span>
</div>
</div>

<div>
<heading id="aplay" class="status">Devices<i class="fa fa-code"></i><?=$help?></heading>
<span class="help-block hide"><code>aplay -l</code></span>
<pre id="codeaplay" class="hide"></pre>
</div>

<div id="divamixer">
<heading id="amixer" class="status">Hardware Mixers<i class="fa fa-code"></i><?=$help?></heading>
<span class="help-block hide"><code>amixer -c N</code></span>
<pre id="codeamixer" class="hide"></pre>
</div>

<div style="clear: both;"></div>
	
<div>
<heading>Bit-Perfect<?=$help?></heading>
<div class="col-l">No Volume</div>
<div class="col-r">
	<input id="novolume" type="checkbox">
	<div class="switchlabel" for="novolume"></div>
	<span class="help-block hide">Disable all software volume manipulations for bit-perfect stream from MPD to DAC and reset DAC hardware volume to 0dB to preserve full amplitude stream.</span>
</div>

<div id="divdop">
	<div class="col-l dop">DSD over PCM</div>
	<div class="col-r dop">
		<input id="dop" type="checkbox">
		<div class="switchlabel" for="dop"></div>
		<span class="help-block hide">For DSD-capable devices without drivers dedicated for native DSD. Enable if there's no sound from the DAC.
			<br>DoP will repack 16bit DSD stream into 24bit PCM frames and transmit to the DAC. 
			Then PCM frames will be reassembled back to original DSD stream, COMPLETELY UNCHANGED, with expense of double bandwith.
			<br>On-board audio and non-DSD devices will always get DSD converted to PCM stream, no bit-perfect</span>
	</div>
</div>
</div>

<div>
<heading>Volume<?=$help?></heading>
<div class="col-l">Crossfade</div>
<div class="col-r">
	<input id="crossfade" class="switch" type="checkbox">
	<div class="switchlabel" for="crossfade"></div>
	<i id="setting-crossfade" class="setting fa fa-gear"></i>
	<span class="help-block hide">Fade-out to fade-in between songs.</span>
</div>
<div class="col-l">Normalization</div>
<div class="col-r">
	<input id="normalization" type="checkbox">
	<div class="switchlabel" for="normalization"></div>
	<span class="help-block hide">Normalize the volume level of songs as they play.</span>
</div>
<div class="col-l">Replay Gain</div>
<div class="col-r">
	<input id="replaygain" type="checkbox">
	<div class="switchlabel" for="replaygain"></div>
	<i id="setting-replaygain" class="setting fa fa-gear"></i>
	<span class="help-block hide">Set gain control to setting in replaygain tag. Currently only FLAC, Ogg Vorbis, Musepack, and MP3 (through ID3v2 ReplayGain tags, not APEv2) are supported.</span>
</div>
</div>

<div>
<heading>Options<?=$help?></heading>
<div class="col-l">Auto Update</div>
<div class="col-r">
	<input id="autoupdate" type="checkbox">
	<div class="switchlabel" for="autoupdate"></div>
	<span class="help-block hide">Automatic update MPD database when files changed.</span>
</div>
<div class="col-l">Custom Buffer</div>
<div class="col-r">
	<input id="buffer" type="checkbox">
	<div class="switchlabel" for="buffer"></div>
	<i id="setting-buffer" class="setting fa fa-gear"></i>
	<span class="help-block hide">Default buffer size: 4096KB (24 seconds of CD-quality audio)</span>
</div>
	<?php if ( file_exists( '/usr/bin/ffmpeg' ) ) { ?>
<div class="col-l">FFmpeg Decoder</div>
<div class="col-r">
	<input id="ffmpeg" type="checkbox">
	<div class="switchlabel" for="ffmpeg"></div>
	<span class="help-block hide">Should be disabled if not used for faster Sources update.
		<br>Decoder for audio filetypes:
		<div style="margin-left: 20px">
			<?php
				$types = shell_exec(
					'types=$( /usr/bin/mpd -V | awk \'/\[ffmpeg/ {$1=""; print}\' )'
						.'; for index in {a..z}'
						.'; do types=$( sed "s/ \($index\)/\n\1/" <<<"$types" )'
						.'; done'
						.'; echo "$types" | sort'
				);
				echo str_replace( "\n", '<br>', $types );
			?>
		</div>
	</span>
</div>
	<?php } ?>
</div>

<div>
<heading id="status" class="status">Status<i class="fa fa-code"></i><i id="restart" class="fa fa-reboot"></i><?=$help?></heading>
<span class="help-block hide">
	<code>systemctl status mpd mpdidle</code>
	<br><i class="fa fa-reboot"></i>&ensp;Restart MPD
</span>
<pre id="codestatus" class="hide"></pre>
</div>

<div>
<heading id="mpdconf" class="status">Configuration<i class="fa fa-code"></i><?=$help?></heading>
<span class="help-block hide"><code>cat /etc/mpd.conf</code></span>
<pre id="codempdconf" class="hide"></pre>
</div>

<div style="clear: both"></div>
