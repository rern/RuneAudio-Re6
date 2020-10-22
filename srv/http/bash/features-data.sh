#!/bin/bash

dirsystem=/srv/http/data/system
snaplatency=$( grep OPTS= /etc/default/snapclient | sed 's/.*latency=\(.*\)"/\1/' )
[[ -z $snaplatency ]] && snaplatency=0

data+='
	  "autoplay"        : '$( [[ -e $dirsystem/autoplay ]] && echo true || echo false )'
	, "gpio"            : '$( [[ -e $dirsystem/gpio ]] && echo true || echo false )'
	, "hostname"        : "'$( hostname )'"
	, "login"           : '$( [[ -e $dirsystem/login ]] && echo true || echo false )'
	, "mpdscribble"     : '$( systemctl -q is-active mpdscribble@mpd && echo true || echo false )'
	, "mpdscribbleuser" : "'$( grep ^username /etc/mpdscribble.conf | cut -d' ' -f3- )'"
	, "passworddefault" : '$( grep -q '$2a$12$rNJSBU0FOJM/jP98tA.J7uzFWAnpbXFYx5q1pmNhPnXnUu3L1Zz6W' $dirsystem/password && echo true || echo false )'
	, "reboot"          : "'$( cat /srv/http/data/shm/reboot 2> /dev/null )'"
	, "snapcast"        : '$( systemctl -q is-active snapserver && echo true || echo false )'
	, "snapclient"      : '$( [[ -e $dirsystem/snapclient ]] && echo true || echo false )'
	, "snaplatency"     : '$snaplatency'
	, "streaming"       : '$( grep -q 'type.*"httpd"' /etc/mpd.conf && echo true || echo false )
# renderer
[[ -e /usr/bin/shairport-sync  ]] && data+='
	, "airplay"         : '$( systemctl -q is-active shairport-sync && echo true || echo false )
[[ -e /usr/bin/spotifyd  ]] && data+='
	, "spotify"         : '$( systemctl -q is-active spotifyd && echo true || echo false )'
	, "spotifydevice"   : "'$( awk '/device =/ {print $NF}' /etc/spotifyd.conf )'"'
[[ -e /usr/bin/upmpdcli  ]] && data+='
	, "upnp"            : '$( systemctl -q is-active upmpdcli && echo true || echo false )
# features
[[ -e /usr/bin/smbd  ]] && data+='
	, "samba"           : '$( systemctl -q is-active smb && echo true || echo false )'
	, "writesd"         : '$( grep -A1 /mnt/MPD/SD /etc/samba/smb.conf | grep -q 'read only = no' && echo true || echo false )'
	, "writeusb"        : '$( grep -A1 /mnt/MPD/USB /etc/samba/smb.conf | grep -q 'read only = no' && echo true || echo false )
xinitrc=/etc/X11/xinit/xinitrc
if [[ -e $xinitrc ]]; then
	file='/etc/X11/xorg.conf.d/99-raspi-rotate.conf'
	[[ -e $file ]] && rotate=$( grep rotate $file | cut -d'"' -f4 ) || rotate=NORMAL
	data+='
	, "cursor"          : '$( grep -q 'cursor yes' $xinitrc && echo true || echo false )'
	, "localbrowser"    : '$( systemctl -q is-enabled localbrowser && echo true || echo false )'
	, "rotate"          : "'$rotate'"
	, "screenoff"       : '$(( $( grep 'xset dpms .*' $xinitrc | cut -d' ' -f5 ) / 60 ))'
	, "zoom"            : '$( grep factor $xinitrc | cut -d'=' -f3 )
fi

echo {$data}
