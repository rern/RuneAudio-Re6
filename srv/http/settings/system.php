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
	<input type="text" id="hostname" readonly>
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

<?php
$listruneos = [
	  'Avahi'                    => 'https://www.avahi.org/'
	, 'BlueZ'                    => 'http://www.bluez.org'
	, 'BlueZ-Alsa'               => 'https://github.com/Arkq/bluez-alsa'
	, 'Chromium'                 => 'https://www.chromium.org/'
	, 'Cronie'                   => 'https://github.com/cronie-crond/cronie'
	, 'Dnsmasq'                  => 'http://www.thekelleys.org.uk/dnsmasq/doc.html'
	, 'dosfstools'               => 'https://github.com/dosfstools/dosfstools'
	, 'FFmpeg'                   => 'http://ffmpeg.org'
	, 'Gifsicle'                 => 'https://www.lcdf.org/gifsicle/'
	, 'hfsprogs'                 => 'https://aur.archlinux.org/packages/hfsprogs'
	, 'hostapd'                  => 'https://w1.fi/hostapd'
	, 'ifplugd'                  => 'http://0pointer.de/lennart/projects/ifplugd'
	, 'ImageMagick'              => 'https://imagemagick.org'
	, 'jq'                       => 'https://stedolan.github.io/jq'
	, 'Kid3 - Audio Tagger'      => 'https://kid3.sourceforge.io'
	, 'MPD'                      => 'http://www.musicpd.org'
	, 'nfs-utils'                => 'http://nfs.sourceforge.net'
	, 'NGINX'                    => 'http://nginx.org'
	, 'NGINX Push Stream Module' => 'https://github.com/wandenberg/nginx-push-stream-module'
	, 'nss-mdns'                 => 'http://0pointer.de/lennart/projects/nss-mdns'
	, 'NTFS-3G'                  => 'https://www.tuxera.com/community/open-source-ntfs-3g'
	, 'Parted'                   => 'https://www.gnu.org/software/parted/parted.html'
	, 'PHP'                      => 'http://php.net'
	, 'ply-image'                => 'https://chromium.googlesource.com/chromiumos/third_party/ply-image/+/refs/heads/master/README.chromium'
	, 'Python'                   => 'https://www.python.org'
	, 'raspi-rotate'             => 'https://github.com/colinleroy/raspi-rotate'
	, 'Samba'                    => 'http://www.samba.org'
	, 'Shairport-sync'           => 'https://github.com/mikebrady/shairport-sync'
	, 'Snapcast'                 => 'https://github.com/badaix/snapcast'
	, 'Spotifyd'                 => 'https://github.com/Spotifyd/spotifyd'
	, 'Sudo'                     => 'https://www.sudo.ws/sudo'
	, 'udevil'                   => 'http://ignorantguru.github.io/udevil'
	, 'upmpdcli'                 => 'http://www.lesbonscomptes.com/upmpdcli'
	, 'Wget'                     => 'https://www.gnu.org/software/wget/wget.html'
	, 'Web Service Discovery'    => 'https://github.com/christgau/wsdd'
	, 'X'                        => 'https://xorg.freedesktop.org'
];
$runeoshtml = '';
foreach( $listruneos as $name => $link ) {
	$runeoshtml.= '<a href="'.$link.'">'.$name.'</a><br>';
}
$listruneui = [
	  'HTML5-Color-Picker'  => 'https://github.com/NC22/HTML5-Color-Picker'
	, 'jQuery'              => 'https://jquery.com/'
	, 'jQuery Mobile'       => 'https://jquerymobile.com/'
	, 'jQuery Selectric'    => 'https://github.com/lcdsantos/jQuery-Selectric'
	, 'Lato-Fonts'          => 'http://www.latofonts.com/lato-free-fonts'
	, 'LazyLoad'            => 'https://github.com/verlok/lazyload'
	, 'pica'                => 'https://github.com/nodeca/pica'
	, 'QR Code generator'   => 'https://github.com/datalog/qrcode-svg'
	, 'roundSlider'         => 'https://github.com/soundar24/roundSlider'
	, 'simple-keyboard'     => 'https://github.com/hodgef/simple-keyboard/'
	, 'Sortable'            => 'https://github.com/SortableJS/Sortable'
];
$runeuihtml = '';
foreach( $listruneui as $name => $link ) {
	$runeuihtml.= '<a href="'.$link.'">'.$name.'</a><br>';
}
?>
<br><br>
<heading>About</heading>
RuneAudio <i class="fa fa-addons gr"></i> <?=( file_get_contents( '/srv/http/data/system/version' ) )?>&emsp;by&emsp;<a href="https://github.com/rern/">r e r n</a>
<div>
<heading class="sub">RuneOS<?=$help?></heading>
<span class="help-block hide">
	<a href="https://www.archlinuxarm.org" style="font-size: 20px;">ArchLinuxArm</a> + default pakages<br>
	<?=$runeoshtml?>
</span>
</div>
<div>
<heading class="sub">RuneUI<?=$help?></heading>
<span class="help-block hide">
	<?=$runeuihtml?>
</span>
</div>
<div>
<heading class="sub">Data<?=$help?></heading>
<span class="help-block hide">
	<a href="https://www.last.fm">last.fm</a><gr> - Coverarts and artist biographies</gr><br>
	<a href="https://webservice.fanart.tv">fanart.tv</a><gr> - Coverarts and artist images</gr><br>
	<a href="https://radioparadise.com">Radio Paradise</a><gr> - Coverarts of their own and default stations</gr>
</span>
</div>

<div style="clear: both"></div>
