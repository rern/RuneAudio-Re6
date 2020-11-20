<?php $code = '<i class="fa fa-code"></i>'; ?>
<div>
<heading>Renderers<?=$help?></heading>
	<?php if ( file_exists( '/usr/bin/shairport-sync' ) ) { ?>
<div data-status="shairport-sync" class="col-l double status">
	<a>AirPlay
	<br><gr>Shairport-sync<?=$code?></gr></a><i class="fa fa-airplay fa-lg"></i>
</div>
<div class="col-r">
	<input id="shairport-sync" type="checkbox">
	<div class="switchlabel" for="shairport-sync"></div>
	<span class="help-block hide">
		<a href="https://github.com/mikebrady/shairport-sync">Shairport-sync</a> - RuneAudio as AirPlay rendering device.
	</span>
</div>
<pre id="codeshairport-sync" class="hide"></pre>
	<?php }
		  if ( file_exists( '/usr/bin/snapserver' ) ) { ?>
<div id="divsnapclient">
	<div class="col-l double">
		<a>SnapClient
		<br><gr>Snapcast</gr></a><i class="fa fa-snapcast fa-lg"></i>
	</div>
	<div class="col-r">
		<input id="snapclient" type="checkbox">
		<div class="switchlabel" for="snapclient"></div>
		<i id="setting-snapclient" class="setting fa fa-gear hide"></i>
		<span class="help-block hide">
			<a href="https://github.com/badaix/snapcast">Snapcast</a> - Multiroom client-server audio player
			<br>SnapClient - Connect: Menu >&ensp;<i class="fa fa-folder-cascade"></i>&ensp;Sources |&ensp;<i class="fa fa-snapcast"></i>
			<br>(Note: Not available while Snapcast server enabled.)
		</span>
	</div>
</div>
	<?php }
		  if ( file_exists( '/usr/bin/spotifyd' ) ) { ?>
<div data-status="spotifyd" class="col-l double status">
	<a>Spotify
	<br><gr>Spotifyd<?=$code?></gr></a><i class="fa fa-spotify fa-lg"></i>
</div>
<div class="col-r">
	<input id="spotifyd" type="checkbox">
	<div class="switchlabel" for="spotifyd"></div>
	<i id="setting-spotifyd" class="setting fa fa-gear hide"></i>
	<span class="help-block hide">
		<a href="https://github.com/Spotifyd/spotifyd">Spotifyd</a> - RuneAudio as Spotify Connect device.(For Premium account only)
		<br><i class="fa fa-gear"></i>&ensp;Manually select audio output (when default not working only)
	</span>
</div>
<pre id="codespotifyd" class="hide"></pre>
	<?php }
		  if ( file_exists( '/usr/bin/upmpdcli' ) ) { ?>
<div data-status="upmpdcli" class="col-l double status">
	<a>UPnP
	<br><gr>upmpdcli<?=$code?></gr></a><i class="fa fa-upnp fa-lg"></i>
</div>
<div class="col-r">
	<input id="upmpdcli" type="checkbox">
	<div class="switchlabel" for="upmpdcli"></div>
	<!--<i id="setting-upnp" class="setting fa fa-gear hide"></i>-->
	<span class="help-block hide">
		<a href="https://www.lesbonscomptes.com/upmpdcli/">upmpdcli</a> - RuneAudio as UPnP / DLNA rendering device.
	</span>
</div>
<pre id="codeupmpdcli" class="hide"></pre>
	<?php } ?>
</div>

<div>
<heading>Streamers<?=$help?></heading>
<div class="col-l double">
	<a>For browsers
	<br><gr>MPD http</gr></a><i class="fa fa-webradio fa-lg"></i>
</div>
<div class="col-r">
	<input id="streaming" type="checkbox">
	<div class="switchlabel" for="streaming"></div>
	<span class="help-block hide">Asynchronous streaming for browsers via <code id="ip"></code> (Latency - several seconds)</span>
</div>
	<?php if ( file_exists( '/usr/bin/snapserver' ) ) { ?>
<div data-status="snapserver" class="col-l double status">
	<a>SnapServer
	<br><gr>Snapcast<?=$code?></gr></a><i class="fa fa-snapcast fa-lg"></i>
</div>
<div class="col-r">
	<input id="snapserver" type="checkbox">
	<div class="switchlabel" for="snapserver"></div>
	<span class="help-block hide">
		<a href="https://github.com/badaix/snapcast">Snapcast</a> - Multiroom client-server audio player
		<br>SnapServer - Clients can be either RPis with RuneAudio+R e or Snapcast capable devices.
		<br>(Note: Enable Snapcast will disable SnapClient.)
	</span>
</div>
<pre id="codesnapserver" class="hide"></pre>
	<?php } ?>
</div>

<div>
<heading>Features<?=$help?></heading>
	<?php if ( file_exists( '/usr/bin/chromium' ) ) { ?>
<div data-status="localbrowser" class="col-l double status">
	<a>Browser on RPi
	<br><gr>Chromium<?=$code?></gr></a><i class="fa fa-chromium fa-lg"></i>
</div>
<div class="col-r">
	<input id="localbrowser" type="checkbox">
	<div class="switchlabel" for="localbrowser"></div>
	<i id="setting-localbrowser" class="setting fa fa-gear"></i>
	<span class="help-block hide">
		<a href="https://github.com/chromium/chromium">Chromium</a> - Browser on RPi connected screen. (Overscan change needs reboot.)
	</span>
</div>
<pre id="codelocalbrowser" class="hide"></pre>
	<?php } 
		  if ( file_exists( '/usr/bin/smbd' ) ) { ?>
<div data-status="smb" class="col-l double status">
	<a>File Sharing
	<br><gr>Samba<?=$code?></gr></a><i class="fa fa-networks fa-lg"></i>
</div>
<div class="col-r">
	<input id="smb" type="checkbox">
	<div class="switchlabel" for="smb"></div>
	<i id="setting-smb" class="setting fa fa-gear"></i>
	<span class="help-block hide">
		<a href="https://www.samba.org">Samba</a> - Share files on RuneAudio.
		<br>Set sources permissions for read+write - directory: <code>0777</code> file: <code>0555</code>
		<br><i class="fa fa-gear"></i>&ensp;Enable/disable write.
	</span>
</div>
<pre id="codesmb" class="hide"></pre>
	<?php } ?>
<div data-status="mpdscribble" class="col-l double status">
	<a>Last.fm Scrobbler
	<br><gr>mpdscribble<?=$code?></gr></a><i class="fa fa-lastfm fa-lg"></i>
</div>
<div class="col-r">
	<input id="mpdscribble" type="checkbox">
	<div class="switchlabel" for="mpdscribble"></div>
	<i id="setting-mpdscribble" class="setting fa fa-gear"></i>
	<span class="help-block hide">
		<a href="https://github.com/MusicPlayerDaemon/mpdscribble">mpdscribble</a> - Automatically send listened music data to Last.fm for tracking.
	</span>
</div>
<pre id="codempdscribble" class="hide"></pre>
<div class="col-l double">
	<a>Password Login
	<br><gr>Blowfish</gr></a><i class="fa fa-lock-circle fa-lg"></i>
</div>
<div class="col-r">
	<input id="login" type="checkbox"<?=( password_verify( 'rune', file_get_contents( '/srv/http/data/system/password' ) ) ? ' data-default="1"' : '' )?>>
	<div class="switchlabel" for="password"></div>
	<i id="setting-login" class="setting fa fa-gear"></i>
	<span class="help-block hide">Browser interface login. (Default: <code>rune</code>)</span>
</div>
<div class="col-l double">
	<a>Play on Startup
	<br><gr>System</gr></a><i class="fa fa-refresh-play fa-lg"></i>
</div>
<div class="col-r">
	<input id="autoplay" type="checkbox">
	<div class="switchlabel" for="autoplay"></div>
	<span class="help-block hide">Start playing automatically after boot.</span>
</div>
<div data-status="hostapd" class="col-l double status">
	<a>RPi Access Point
	<br><gr>hostapd<?=$code?></gr></a><i class="fa fa-wifi-3 fa-lg"></i>
</div>
<div class="col-r">
	<input id="hostapd" type="checkbox">
	<div class="switchlabel" for="hostapd"></div>
	<i id="setting-hostapd" class="setting fa fa-gear"></i>
	<span class="help-block hide">Connect with RuneAudio+R Wi-Fi directly when no routers available.
		<br>RuneAudio+R access point should be used only when necessary.</span>
</div>
<pre id="codehostapd" class="hide"></pre>

</div>

<div style="clear: both"></div>
