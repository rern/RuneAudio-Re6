#!/bin/bash

dirtmp=/srv/http/data/shm
snapserverfile=$dirtmp/snapserverip
snapclientfile=$dirtmp/snapclientip
playerfile=$dirtmp/player

if [[ $1 == start ]]; then # client start - save server ip
	mpc stop
	systemctl start snapclient
	sleep 2
	serverip=$( systemctl status snapclient | awk '/Connected to/ {print $NF}' )
	if [[ -n $serverip ]]; then
		echo '"mpd":false,"airplay":false,"snapclient":true,"spotify":false,"upnp":false' > $playerfile
		rm -f $playerfile-*
		touch $playerfile-snapclient
		echo $serverip > $snapserverfile
		clientip=$( ifconfig | awk '/inet .*broadcast/ {print $2}' )
		curl -s -X POST http://$serverip/pub?id=snapcast -d '{ "add": "'$clientip'" }'
		systemctl try-restart shairport-sync spotifyd upmpdcli &> /dev/null
	else
		systemctl stop snapclient
		echo -1
	fi
elif [[ $1 == stop ]]; then # client stop - delete server ip, curl remove client ip
	echo stop
	systemctl stop snapclient
	echo '"mpd":true,"airplay":false,"snapclient":false,"spotify":false,"upnp":false' > $playerfile
	rm -f $playerfile-*
	touch $playerfile-mpd
	serverip=$( cat $snapserverfile )
	clientip=$( ifconfig | awk '/inet .*broadcast/ {print $2}' )
	rm $snapserverfile
	curl -s -X POST http://$serverip/pub?id=snapcast -d '{ "remove": "'$clientip'" }'
elif [[ $1 == add ]]; then # connected from client - save client ip
	clientip=$2
	! grep -q $clientip $snapclientfile 2> /dev/null && echo $clientip >> $snapclientfile
elif [[ $1 == remove ]]; then # disconnected from client - remove client ip
	clientip=$2
	sed -i "/$clientip/ d" $snapclientfile
elif [[ $1 == serverstop ]]; then # force clients stop
	snapclientfile=$dirtmp/snapclientip
	if [[ -e $snapclientfile ]]; then
		sed -i '/^$/d' $snapclientfile # remove blank lines
		if [[ -s $snapclientfile ]]; then
			mapfile -t clientip < $snapclientfile
			for ip in "${clientip[@]}"; do
				curl -s -X POST http://$ip/pub?id=snapcast -d -1
			done
		fi
		rm -f $snapclientfile
	fi
fi