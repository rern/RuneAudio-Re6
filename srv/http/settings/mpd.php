<div id="divmain"> <!-- ************************************************* -->

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
	<span class="help-block hide">
			<code>mpc crossfade N</code>
		<br>Fade-out to fade-in between songs.
	</span>
</div>
<div class="col-l">Normalization</div>
<div class="col-r">
	<input id="normalization" type="checkbox">
	<div class="switchlabel" for="normalization"></div>
	<span class="help-block hide">
			<code>volume_normalization "yes"</code>
		<br>Normalize the volume level of songs as they play.
	</span>
</div>
<div class="col-l">Replay Gain</div>
<div class="col-r">
	<input id="replaygain" type="checkbox">
	<div class="switchlabel" for="replaygain"></div>
	<i id="setting-replaygain" class="setting fa fa-gear"></i>
	<span class="help-block hide">
			<code>replaygain "N"</code>
		<br>Set gain control to setting in replaygain tag. Currently only FLAC, Ogg Vorbis, Musepack, and MP3 (through ID3v2 ReplayGain tags, not APEv2) are supported.
	</span>
</div>
</div>

<div>
<heading>Options<?=$help?></heading>
<div class="col-l double">
	<a>Auto Update
	<br><gr>Library</gr></a>
</div>
<div class="col-r">
	<input id="autoupdate" type="checkbox">
	<div class="switchlabel" for="autoupdate"></div>
	<span class="help-block hide">
			<code>auto_update "yes"</code>
		<br>Automatic update MPD database when files changed.
	</span>
</div>
<div class="col-l double">
	<a>FFmpeg
	<br><gr>decoder</gr></a>
</div>
<div class="col-r">
	<input id="ffmpeg" type="checkbox">
	<div class="switchlabel" for="ffmpeg"></div>
	<span class="help-block hide">
			<code>enable "yes"</code>
		<br>Should be disabled if not used for faster Sources update.
		<br>Decoder for audio filetypes:&emsp;<i id="filetype" class="fa fa-question-circle"></i>
		<div id="divfiletype" class="hide" style="margin-left: 20px"><?=( shell_exec( '/srv/http/bash/mpd.sh filetype' ) )?></div>
	</span>
</div>
<div class="col-l double">
	<a>Audio Buffer
	<br><gr>custom size</gr></a>
</div>
<div class="col-r">
	<input id="buffer" type="checkbox">
	<div class="switchlabel" for="buffer"></div>
	<i id="setting-buffer" class="setting fa fa-gear"></i>
	<span class="help-block hide">
			<code>audio_buffer_size "kB"</code>
		<br>Default buffer size: 4096 kB (24 seconds of CD-quality audio)
		<br>Increase to fix intermittent audio.
	</span>
</div>
<div class="col-l double">
		<a>Output Buffer
	<br><gr>custom size</gr></a>
</div>
<div class="col-r">
	<input id="bufferoutput" type="checkbox">
	<div class="switchlabel" for="bufferoutput"></div>
	<i id="setting-bufferoutput" class="setting fa fa-gear"></i>
	<span class="help-block hide">
			Default buffer size: 8192 kB
		<br>Increase to fix missing Album list with large Library.
	</span>
</div>
<div class="col-l double">
		<a>Resampling
	<br><gr>SoXR custom values</gr></a>
</div>
<div class="col-r">
	<input id="soxr" type="checkbox">
	<div class="switchlabel" for="soxr"></div>
	<i id="setting-soxr" class="setting fa fa-gear"></i>
	<span class="help-block hide">
			SoX Resampler custom settings:
		<br>&bull; Precision - Conversion precision <code>16, 20, 24, 28 or 32</code> bits (20 = HQ)
		<br>&bull; Phase Response <code>0-100</code> (50 = Linear)
		<br>&bull; Passband End - 0dB point bandwidth to preserve <code>1-100</code> % (100 = Nyquist)
		<br>&bull; Stopband Begin - Aliasing/imaging control <code>100-150</code> %
		<br>&bull; Attenuation - Lowers the source to prevent clipping <code>0-30</code> dB
		<br>&bull; Flags - Extra settings: <code>0, 1, 2, 8, 16 or 32</code>
		<br> &emsp; 0 - Rolloff <= 0.01 dB
		<br> &emsp; 1 - Rolloff <= 0.35 dB
		<br> &emsp; 2 - Rolloff none - For Chebyshev bandwidth
		<br> &emsp; 8 - High precision - Increase irrational ratio accuracy
		<br> &emsp; 16 - Double precision even if Precision <= 20
		<br> &emsp; 32 - Variable rate resampling
	</span>
</div>
<div class="col-l">User's Custom Settings</div>
<div class="col-r">
	<input id="custom" type="checkbox">
	<div class="switchlabel" for="custom"></div>
	<i id="setting-custom" class="setting fa fa-gear"></i>
	<span class="help-block hide">Insert settings into <code>/etc/mpd.conf</code>.</span>
</div>
</div>

</div> <!-- divmain ****************************************** -->

<div>
<heading id="mpdconf" class="status">Configuration<i class="fa fa-code"></i><?=$help?></heading>
<span class="help-block hide"><code>cat /etc/mpd.conf</code></span>
<pre id="codempdconf" class="hide"></pre>

<div>
<heading id="mpd" class="status">Status<i class="fa fa-code"></i><i id="mpdrestart" class="fa fa-reboot"></i><?=$help?></heading>
<span class="help-block hide">
	<code>systemctl status mpd</code>
	<br><i class="fa fa-reboot"></i>&ensp;Restart MPD
</span>
<pre id="codempd" class="hide"></pre>
</div>

<!--
<div class="col-l">Manual Mode</div>
<div class="col-r">
	<input id="manualconf" type="checkbox">
	<div class="switchlabel" for="manualconf"></div>
	<i id="setting-manualconf" class="setting fa fa-save"></i>
	<span class="help-block hide">
			Manually set MPD configuration, <code>mpd.conf</code>. Once enabled, any further changes, options or audio devices, must be reconfigured manually.
		<br>This will also disable:
		<br>&emsp; &bull; USB DAC plug and play for MPD, AirPlay and Spotify.
		<br>&emsp; &bull; Bluetooth auto connect.
	</span>
</div>
<textarea id="codemanualconf" spellcheck="false"></textarea>
</div>
-->
<div style="clear: both"></div>
