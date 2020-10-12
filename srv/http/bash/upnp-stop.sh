#!/bin/bash

playerfile=/srv/http/data/shm/player
if [[ -e $playerfile-upnp ]]; then
	systemctl restart upmpdcli
	echo '"mpd":true,"airplay":false,"snapclient":false,"spotify":false,"upnp":false' > $playerfile
	rm -f $playerfile-*
	touch $playerfile-mpd
	mpc del 1
	curl -s -X POST http://127.0.0.1/pub?id=mpdplayer -d "$( /srv/http/bash/status.sh )"
fi
