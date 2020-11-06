<div>
<heading class="noline">Devices<i id="addnas" class="fa fa-plus-circle"></i>&emsp;<i id="refreshing" class="fa fa-networks blink hide"></i><?=$help?></heading>
<ul id="list" class="entries" data-uid="<?=( exec( "$sudo/id -u mpd" ) )?>" data-gid="<?=( exec( "$sudo/id -g mpd" ) )?>"></ul>
<p class="brhalf"></p>
<span class="help-block hide">
	Available sources, local USB and NAS mounts, for Library.
	<br>USB drive will be found and mounted automatically. Network shares must be manually configured.
</span>
</div>

<div>
<heading id="mount" class="status">Mounts<i class="fa fa-code"></i><?=$help?></heading>
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
<heading id="fstab" class="status">File System Table<i class="fa fa-code"></i><?=$help?></heading>
<span class="help-block hide"><code>cat /etc/fstab</code></span>
<pre id="codefstab" class="hide"></pre>
</div>

<div style="clear: both"></div>
