<div id="divinterface">
<?php if ( exec ( 'ifconfig | grep ^eth' ) ) { ?>
	<heading id="headlan" class="noline">LAN<i id="lanadd" class="fa fa-plus-circle"></i></heading>
	<ul id="listlan" class="entries"></ul>
<?php }
	  $wlan = exec ( 'ifconfig | grep ^wlan' );
	  if ( $wlan ) { ?>
	<div>
	<heading id="headwl" class="noline">Wi-Fi<i id="wladd" class="fa fa-plus-circle"></i><i id="wlscan" class="fa fa-search"></i><?=$help?></heading>
	<ul id="listwl" class="entries"></ul>
	<span class="help-block hide">
		Use wired LAN if possible for better performance.
	</span>
	</div>
<?php }
	  if ( exec( 'systemctl -q is-active bluetooth && echo 1 || echo 0' ) ) { ?>
	<div>
	<heading id="headbt" class="noline">Bluetooth<i id="btscan" class="fa fa-search"></i><?=$help?></heading>
	<ul id="listbt" class="entries"></ul>
	<span class="help-block hide">
			- As sender(source) to send signal to another device.
		<br>- As receiver(sink) to receive signal from another device
	</span>
	</div>
<?php } ?>
	
	<div>
	<heading>Web User Interface<?=$help?></heading>
	<div id="divwebui" class="hide">
		<div class="col-l">URL</div>
		<div class="col-r">
			<gr>http://</gr><span id="ipwebui"></span><br>
			<div id="qrwebui" class="qr"></div>
			<span class="help-block hide">Scan QR code or use IP address to connect RuneAudio web user interface.</span>
		</div>
	</div>
	</div>
</div>

<div id="divwifi" class="hide">
	<div>
	<heading class="noline">Wi-Fi
		<i id="add" class="fa fa-plus-circle"></i><i id="scanning-wifi" class="fa fa-wifi-3 blink"></i>
		<?=$help?><i class="fa fa-arrow-left back"></i>
	</heading>
	<ul id="listwlscan" class="entries"></ul>
	<span class="help-block hide">Access points with less than -66dBm should not be used.</span>
	</div>
	
	<div>
	<heading id="netctl" class="status">Saved Profiles<i class="fa fa-code"></i><?=$help?></heading>
	<span class="help-block hide"><code>cat /etc/netctl/SSID</code></span>
	<pre id="codenetctl" class="hide"></pre>
	</div>
</div>

<div id="divbluetooth" class="hide">
	<heading class="noline">Bluetooth
		<i id="scanning-bt" class="fa fa-bluetooth blink"></i>
		<i class="fa fa-arrow-left back"></i>
	</heading>
	<ul id="listbtscan" class="entries"></ul>
</div>

	<?php if ( $wlan && file_exists( '/usr/bin/hostapd' ) ) { ?>
<div id="divaccesspoint">
	<heading>RPi Access Point<?=$help?></heading>
	<div class="col-l">Enable</div>
	<div class="col-r">
		<input id="accesspoint" type="checkbox">
		<div class="switchlabel" for="accesspoint"></div>
		<i id="setting-accesspoint" class="setting fa fa-gear"></i>
		<span class="help-block hide">Connect with RuneAudio+R Wi-Fi directly when no routers available.
			<br>RuneAudio+R access point should be used only when necessary.</span>
	</div>
	<p class="brhalf"></p>
	<div id="boxqr" class="hide">
		<div class="col-l">Credential</div>
		<div class="col-r">
			<gr>SSID:</gr> <span id="ssid"></span><br>
			<gr>Password:</gr> <span id="passphrase"></span>
			<div id="qraccesspoint" class="qr"></div>
			<span class="help-block hide">Scan QR code or find the SSID and use the password to connect remote devices with RuneAudio+R access point.</span>
		</div>
		<div class="col-l">Web UI</div>
		<div class="col-r">
			<gr>http://</gr><span id="ipwebuiap"></span>
			<div class="divqr">
				<div id="qrwebuiap" class="qr"></div>
			</div>
			<span class="help-block hide">Scan QR code or use the IP address to connect RuneAudio web user interface with any browsers from remote devices.</span>
		</div>
	</div>
</div>
	<?php } ?>

<div style="clear: both"></div>
