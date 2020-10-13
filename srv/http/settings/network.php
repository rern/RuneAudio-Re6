<div id="divinterface">
	<div>
	<heading class="noline">Interfaces<i id="refreshing" class="fa fa-wifi-3 blink hide"></i><?=$help?></heading>
	<ul id="listinterfaces" class="entries"></ul>
	<span class="help-block hide">
		<wh>LAN</wh>:
		<br>- Use wired LAN if possible for better performance.
	<?php if ( file_exists( '/usr/bin/bluetoothctl' ) ) { ?>
		<br><wh>Bluetooth</wh>:
		<br>- Paired devices reconnect automatically when power on.
		<br>- Scan for devices while listening makes Bluetooth audio choppy.
	<?php } ?>		<br><br></span>

	<div id="divwebui" class="hide">
		<div class="col-l">Web UI</div>
		<div class="col-r">
			<gr>http://</gr><span id="ipwebui"></span><br>
			<div id="qrwebui" class="qr"></div>
			<span class="help-block hide">Scan QR code or use IP address to connect RuneAudio web user interface.</span>
		</div>
	</div>
	</div>
	
	<div>
	<heading id="ifconfig" class="status">Status<i class="fa fa-code"></i><?=$help?></heading>
	<span class="help-block hide"><code>ifconfig</code></span>
	<pre id="codeifconfig" class="hide"></pre>
	</div>
</div>

<div id="divwifi" class="hide">
	<div>
	<heading class="noline">Wi-Fi
		<i id="add" class="fa fa-plus-circle"></i><i id="scanning-wifi" class="fa fa-wifi-3 blink"></i>
		<?=$help?><i class="fa fa-arrow-left back"></i>
	</heading>
	<ul id="listwifi" class="entries"></ul>
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
	<ul id="listbt" class="entries"></ul>
</div>

	<?php if ( file_exists( '/usr/bin/hostapd' ) ) { ?>
<div id="divaccesspoint">
	<heading>RPi Access Point<?=$help?></heading>
	<div class="col-l">Enable</div>
	<div class="col-r">
		<input id="accesspoint" type="checkbox">
		<div class="switchlabel" for="accesspoint"></div>
		<i id="settings-accesspoint" class="setting fa fa-gear"></i>
		<span class="help-block hide">Connect with RPi Wi-Fi directly when no routers available.
			<br>RPi access point should be used only when necessary.</span>
	</div>
	<p class="brhalf"></p>
	<div id="boxqr" class="hide">
		<div class="col-l">Credential</div>
		<div class="col-r">
			<gr>SSID:</gr> <span id="ssid"></span><br>
			<gr>Password:</gr> <span id="passphrase"></span>
			<div id="qraccesspoint" class="qr"></div>
			<span class="help-block hide">Scan QR code or find the SSID and use the password to connect remote devices with RPi access point.</span>
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
