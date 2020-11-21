<?php
$uid = exec( "$sudo/id -u mpd" );
$gid = exec( "$sudo/id -g mpd" );
?>
<div>
<heading class="noline">Devices<i id="addnas" class="fa fa-plus-circle"></i>&emsp;<i id="refreshing" class="fa fa-networks blink hide"></i><?=$help?></heading>
<ul id="list" class="entries" data-uid="<?=$uid?>" data-gid="<?=$gid?>"></ul>
<p class="brhalf"></p>
<span class="help-block hide">
	Available sources, local USB and NAS mounts, for Library.
	<br>USB drive will be found and mounted automatically. Network shares must be manually configured.
	<br>
	<br><i class="fa fa-plus-circle"></i>&ensp; Add network share commands used:
	<br> &emsp; <gr>(If mount failed, try in termenal to see errors.)</gr>
	<br>#1: <code>mkdir -p "/mnt/MPD/NAS/<bll>NAME</bll>"</code>
	<br>#2: (in one single line)
	<br> &emsp; CIFS:
	<br> &emsp; <code>mount -t cifs "//<bll>IP</bll>/<bll>SHARE</bll>" "/mnt/MPD/NAS/<bll>NAME</bll>" -o noauto,username=<bll>USER</bll>,password=<bll>PASSWORD</bll>,uid=<?=$uid?>,gid=<?=$gid?>,iocharset=utf8</code>
	<br> &emsp; NFS:
	<br> &emsp; <code>mount -t nfs "<bll>IP</bll>:/<bll>SHARE</bll>" "/mnt/MPD/NAS/<bll>NAME</bll>" -o defaults,noauto,bg,soft,timeo=5</code>
	<br>#3: If options required, append #2 with <code>,<bll>OPTIONS</bll></code>
</span>
</div>

<div>
<heading data-status="mount" class="status">Mounts<i class="fa fa-code"></i><?=$help?></heading>
<span class="help-block hide"><code>mount | grep ' / \|MPD'</code></span>
<pre id="codemount" class="hide"></pre>
</div>

<?php /*<div>
<heading class="noline">Network Shares<i id="refreshshares" class="fa fa-refresh hide"></i></heading>
<ul id="listshare" class="entries">
	<li><i class="fa fa-search"></i><gr>Scan</gr></li>
</ul>
<p class="brhalf"></p>
<span class="help-block hide">
	Available Windows and CIFS shares in WORKGROUP. Scan and select a share to mount as Library source files.
</span>
</div> */ ?>

<div>
<heading data-status="fstab" class="status">File System Table<i class="fa fa-code"></i><?=$help?></heading>
<span class="help-block hide"><code>cat /etc/fstab</code></span>
<pre id="codefstab" class="hide"></pre>
</div>

<div style="clear: both"></div>
