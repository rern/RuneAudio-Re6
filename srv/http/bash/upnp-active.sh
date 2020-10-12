#!/bin/bash

playerfile=/srv/http/data/shm/player
[[ -e $playerfile-upnp ]] && exit

for pid in $( pgrep upmpdcli ); do
	ionice -c 0 -n 0 -p $pid &> /dev/null 
	renice -n -19 -p $pid &> /dev/null
done

urlnet=$( mpc playlist -f %file% | head -1 | sed 's|.*//\(.*\):.*|\1|' | cut -d. -f1-2 )
gatewaynet=$( ip route | awk '/default/ {print $3}' | cut -d. -f1-2 )
if [[ $gatewaynet == $urlnet ]]; then
	echo '"mpd":false,"airplay":false,"snapclient":false,"spotify":false,"upnp":true' > $playerfile
	rm -f $playerfile-*
	touch $playerfile-upnp
	systemctl try-restart shairport-sync snapclient spotifyd &> /dev/null
fi
