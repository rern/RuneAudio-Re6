<?php
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
$listruneos = [
	  'Avahi'                    => 'https://www.avahi.org/'
	, 'BlueZ'                    => 'http://www.bluez.org'
	, 'BlueZ-Alsa'               => 'https://github.com/Arkq/bluez-alsa'
	, 'Chromium'                 => 'https://www.chromium.org/'
	, 'Cronie'                   => 'https://github.com/cronie-crond/cronie'
	, 'Dnsmasq'                  => 'http://www.thekelleys.org.uk/dnsmasq/doc.html'
	, 'dosfstools'               => 'https://github.com/dosfstools/dosfstools'
	, 'FFmpeg'                   => 'http://ffmpeg.org'
	, 'GCC'                      => 'http://gcc.gnu.org'
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
?>
<heading>RuneAudio<i class="fa fa-addons gr"></i><?=( file_get_contents( '/srv/http/data/system/version' ) )?></heading>
<a href="https://github.com/rern/">r e r n</a><br>
<span class="help-block hide">
	System-wide improvement with features based on <a href="https://www.runeaudio.com/forum/runeui-enhancement-t4207.html">RuneUI Enhancement</a><br>
</span>
<div>
	<heading>RuneUI<?=$help?></heading>
	<span class="help-block hide">
		<?=$runeuihtml?>
	</span>
</div>
<div>
	<heading>RuneOS<?=$help?></heading>
	<span class="help-block hide">
		<a href="https://www.archlinuxarm.org" style="font-size: 20px;">ArchLinuxArm</a> + default pakages<br>
		<?=$runeoshtml?>
	</span>
</div>
<div>
	<heading>Data<?=$help?></heading>
	<span class="help-block hide">
		<a href="https://www.last.fm">last.fm</a><gr> - Coverarts and artist biographies</gr><br>
		<a href="https://webservice.fanart.tv">fanart.tv</a><gr> - Coverarts and artist images</gr>
	</span>
</div>
<div style="clear: both"></div>
