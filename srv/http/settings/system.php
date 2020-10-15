<?php
$i2slist = json_decode( file_get_contents( '/srv/http/settings/system-i2s.json' ) );
$selecti2s = '<select id="i2smodule">';
foreach( $i2slist as $name => $sysname ) {
	$selecti2s.= '<option value="'.$sysname.'">'.$name.'</option>';
}
$selecti2s.= '</select>';
$timezone = exec( "timedatectl | awk '/zone:/ {print $3}'" );
date_default_timezone_set( $timezone );
$timezonelist = timezone_identifiers_list();
$selecttimezone = '<select id="timezone">';
foreach( $timezonelist as $key => $zone ) {
	$datetime = new DateTime( 'now', new DateTimeZone( $zone ) );
	$offset = $datetime->format( 'P' );
	$zonename = preg_replace( [ '/_/', '/\//' ], [ ' ', ' <gr>&middot;</gr> ' ], $zone );
	$selecttimezone.= '<option value="'.$zone.'">'.$zonename.'&ensp;'.$offset.'</option>\n';
}
$selecttimezone.= '</select>';
$helpstatus = '<i class="fa fa-code w2x"></i>Tap label: <code>systemctl status SERVICE</code></span>';
$code = '<i class="fa fa-code"></i>';
?>
<div>
<heading>System<?=$help?></heading>
<div id="systemlabel" class="col-l text gr"></div>
<div id="system" class="col-r text"></div>
<div class="col-r">
	<span class="help-block hide"><br><i class="fa fa-gear"></i>&ensp;Shortcut to each setting</span>
</div>
</div>

<div>
<heading id="refresh" class="status">Status<i class="fa fa-refresh"></i><?=$help?></heading>
<div id="statuslabel" class="col-l text gr"></div>
<div id="status" class="col-r text"></div>

<div class="col-l"></div>
<div class="col-r">
	<span class="help-block hide">
		<br><gr><i class="fa fa-refresh"></i>&emsp;Toggle refresh every 10 seconds.</gr>
		<br>
		<br>CPU Load: Average number of processes which are being executed and in waiting calculated over 1, 5 and 15 minutes. Each one should not be constantly over 0.75 x CPU cores.
		<br>CPU temperature:
		<div style="margin-left: 20px">
			- 80-84°C: ARM cores throttled.
			<br>- 85°C: ARM cores and GPU throttled.
			<br>- RPi 3B+: 60°C soft limit (optimized throttling)
		</div>
	</span>
</div>
</div>

<div>
<heading>Renderers<?=$help?></heading>
<span class="help-block hide"><?=$helpstatus?>
	<?php if ( file_exists( '/usr/bin/shairport-sync' ) ) { ?>
<div class="col-l double status" data-service="shairport-sync">
	<a>AirPlay
	<br><gr>Shairport-sync<?=$code?></gr></a><i class="fa fa-airplay fa-lg"></i>
</div>
<div class="col-r">
	<input id="airplay" type="checkbox">
	<div class="switchlabel" for="airplay"></div>
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
<div class="col-l double status" data-service="spotifyd">
	<a>Spotify
	<br><gr>Spotifyd<?=$code?></gr></a><i class="fa fa-spotify fa-lg"></i>
</div>
<div class="col-r">
	<input id="spotify" type="checkbox">
	<div class="switchlabel" for="spotify"></div>
	<i id="setting-spotify" class="setting fa fa-gear hide"></i>
	<span class="help-block hide">
		<a href="https://github.com/Spotifyd/spotifyd">Spotifyd</a> - RuneAudio as Spotify Connect device.(For Premium account only)
		<br><i class="fa fa-gear"></i>&ensp;Manually select audio output (when default not working only)
	</span>
</div>
<pre id="codespotifyd" class="hide"></pre>
	<?php }
		  if ( file_exists( '/usr/bin/upmpdcli' ) ) { ?>
<div class="col-l double status" data-service="upmpdcli">
	<a>UPnP
	<br><gr>upmpdcli<?=$code?></gr></a><i class="fa fa-upnp fa-lg"></i>
</div>
<div class="col-r">
	<input id="upnp" type="checkbox">
	<div class="switchlabel" for="upnp"></div>
	<i id="setting-upnp" class="setting fa fa-gear hide"></i>
	<span class="help-block hide">
		<a href="https://www.lesbonscomptes.com/upmpdcli/">upmpdcli</a> - RuneAudio as UPnP / DLNA rendering device.
	</span>
</div>
<pre id="codeupmpdcli" class="hide"></pre>
	<?php } ?>
</div>

<div>
<heading>Streamers<?=$help?></heading>
<span class="help-block hide"><?=$helpstatus?>
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
<div class="col-l double status" data-service="snapserver">
	<a>Synchronous
	<br><gr>Snapcast<?=$code?></gr></a><i class="fa fa-snapcast fa-lg"></i>
</div>
<div class="col-r">
	<input id="snapcast" type="checkbox">
	<div class="switchlabel" for="snapcast"></div>
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
<span class="help-block hide"><?=$helpstatus?>
	<?php if ( file_exists( '/usr/bin/chromium' ) ) { ?>
<div class="col-l double status" data-service="localbrowser">
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
<div class="col-l double status" data-service="smb">
	<a>File Sharing
	<br><gr>Samba<?=$code?></gr></a><i class="fa fa-network fa-lg"></i>
</div>
<div class="col-r">
	<input id="samba" type="checkbox">
	<div class="switchlabel" for="samba"></div>
	<i id="setting-samba" class="setting fa fa-gear"></i>
	<span class="help-block hide">
		<a href="https://www.samba.org">Samba</a> - Share files on RuneAudio.
		<br>Set sources permissions for read+write - directory: <code>0777</code> file: <code>0555</code>
		<br><i class="fa fa-gear"></i>&ensp;Enable/disable write.
	</span>
</div>
<pre id="codesmb" class="hide"></pre>
	<?php }
		  if ( file_exists( '/srv/http/data/system/gpio.json' ) ) { ?>
<div class="col-l double">
	<a>GPIO Relay
	<br><gr>RPI.GPIO</gr></a><i class="fa fa-gpio fa-lg"></i>
</div>
<div class="col-r">
	<input id="gpio" type="checkbox">
	<div class="switchlabel" for="gpio"></div>
	<span class="help-block hide">
		<a href="https://github.com/rern/RuneUI_GPIO/blob/master/README.md">RuneUI - GPIO</a> - Control GPIO-connected relay module for power on / off equipments.
	</span>
</div>
	<?php } ?>
<div class="col-l double status" data-service="mpdscribble">
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
</div>

<div>
<heading>Audio<?=$help?></heading>
<div class="col-l">I&#178;S Module</div>
<div class="col-r i2s">
	<div id="divi2smodulesw">
		<input id="i2smodulesw" type="checkbox">
		<div class="switchlabel" for="i2smodulesw"></div>
	</div>
	<div id="divi2smodule">
		<?=$selecti2s?>
	</div>
	<span class="help-block hide">I&#178;S modules are not plug-and-play capable. Select a driver for installed device.</span>
</div>

<div class="col-l">Sound Profile</div>
<div class="col-r">
	<input id="soundprofile" type="checkbox">
	<div class="switchlabel" for="soundprofile"></div>
	<i id="setting-soundprofile" class="setting fa fa-gear"></i>
	<span class="help-block hide">Tweak system parameters:
		<br><code>sysctl vm.swappiness=N</code>
		<br><code>sysctl kernel.sched_latency_ns=NS</code>
		<div id="eth0help">
			<code>ip link set eth0 mtu BYTE</code>
			<br><code>ip link set eth0 txqueuelen N</code>
		</div>
	</span>
</div>
</div>

<div>
<heading>On-board Devices<?=$help?></heading>
<div id="divonboardaudio">
	<div class="col-l">Audio</div>
	<div class="col-r">
		<input id="onboardaudio" type="checkbox">
		<div class="switchlabel" for="onboardaudio"></div>
		<span class="help-block hide">Should be disabled if use other devices as audio output.</span>
	</div>
</div>
	<?php $code = exec( "awk '/Revision/ {print \$NF}' /proc/cpuinfo" );
		$hwcode = substr( $code, -3, 2 );
		if ( in_array( $hwcode, [ '0c', '08', '0e', '0d', '11' ] ) ) { # rpi with wireless
			if ( file_exists( '/usr/bin/bluetoothctl' ) ) { ?>
<div class="col-l settings" data-setting="network">Bluetooth<i class="fa fa-gear"></i></div>
<div class="col-r">
	<input id="bluetooth" type="checkbox">
	<div class="switchlabel" for="bluetooth"></div>
	<span class="help-block hide">Should be disabled if not used.</span>
</div>
		<?php $bluetooth = ', Bluetooth';
			  } ?>
<div class="col-l settings" data-setting="network">Wi-Fi<i class="fa fa-gear"></i></div>
<div class="col-r">
	<input id="wlan" type="checkbox">
	<div class="switchlabel" for="wlan"></div>
	<span class="help-block hide">Should be disabled if not used.</span>
</div>
	<?php } ?>
</div>

<div>
<heading>Environment<?=$help?></heading>
<div class="col-l">Name</div>
<div class="col-r">
	<input type="text" id="hostname" readonly style="cursor: pointer">
	<span class="help-block hide">Name for Renderers, Streamers, RPi access point<?=$bluetooth?> and system hostname.</span>
</div>
<div class="col-l">Timezone</div>
<div class="col-r">
	<?=$selecttimezone?>
	<i id="setting-regional" class="settingedit fa fa-gear"></i>
	<span class="help-block hide">
		<i class="fa fa-gear"></i>&ensp;Set:
		<br>- NTP - Network Time Protocol server
		<br>- Wi-Fi regulatory domain:
		<p style="margin: 0 0 0 20px">00 = Least common denominator settings, channels and transmit power are permitted in all countries.
		<br>Active regulatory domian may be reassigned by connected router.</p>
	</span>
</div>
<div>
<heading id="journalctl" class="status">Boot Log<i id="journalctlicon" class="fa fa-code"></i><?=$help?></heading>
<span class="help-block hide"><code>journalctl -b | sed -n '1,/Startup finished/ p'</code></span>
<pre id="codejournalctl" class="hide"></pre>
</div>

<div>
<heading id="configtxt" class="status">/boot/config.txt<i class="fa fa-code"></i><?=$help?></heading>
<span class="help-block hide"><code>cat /boot/config.txt</code></span>
<pre id="codeconfigtxt" class="hide"></pre>
</div>

<div>
<heading id="backuprestore" class="status">Backup/Restore Settings<i class="fa fa-gear"></i><?=$help?></heading>
<span class="help-block hide">Backup or restore all settings and  MPD database.</span>
</div>

<div style="clear: both"></div>
