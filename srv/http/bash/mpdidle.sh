#!/bin/bash

for pid in $( pgrep mpd ); do
	ionice -c 0 -n 0 -p $pid &> /dev/null 
	renice -n -19 -p $pid &> /dev/null
done

pushstream() {
	[[ -z $3 ]] && ip=127.0.0.1 || ip=$3
	curl -s -X POST http://$ip/pub?id=$1 -d "$2"
}

dirtmp=/srv/http/data/shm
flag=$dirtmp/flag
flagpl=$dirtmp/flagpl
flagpladd=$dirtmp/flagpladd
snapclientfile=$dirtmp/snapclientip

mpc idleloop | while read changed; do
	[[ $changed == playlist && $( mpc current -f %file% | cut -c1-4 ) == http ]] && continue
	
	case $changed in
		player )
			if [[ ! -e $flag ]]; then # track change only
				touch $flag
				currentprev=$current
				current=$( mpc current )
				if [[ -z $current || $current != $currentprev ]]; then
					killall status-coverartonline.sh &> /dev/null # kill if still running
					if [[ ! -e $dirtmp/player-snapclient ]]; then
						pushstream mpdplayer "$( /srv/http/bash/status.sh )"
						if [[ -e /srv/http/data/system/librandom ]]; then
							counts=$( mpc | awk '/\[playing\]/ {print $2}' | tr -d '#' )
							pos=${counts/\/*}
							total=${counts/*\/}
							if (( $(( total - pos )) < 2 )); then
								sleep 1
								/srv/http/bash/cmd.sh randomfile
								touch $flagpl
							fi
						fi
					else
						sed -i '/^$/d' $snapclientfile # remove blank lines
						if [[ -s $snapclientfile ]]; then
							mapfile -t clientip < $snapclientfile
							for ip in "${clientip[@]}"; do
								pushstream mpdplayer "$( /srv/http/bash/status.sh )" $ip
							done
						else
							rm $snapclientfile
						fi
					fi
					[[ -e $flagpl ]] && pushstream playlist "$( php /srv/http/mpdplaylist.php current )"
				fi
				rm -f $flag $flagpl
			fi
			;;
		playlist ) # consume mode: playlist+player at once - run player fisrt
			if [[ $( mpc | awk '/^volume:.*consume:/ {print $NF}' ) == on && ! -e $flagpladd ]]; then
				( sleep 0.05
					if [[ -e $flag ]]; then
						touch $flagpl
					else
						rm -f $flagpl
						pushstream playlist "$( php /srv/http/mpdplaylist.php current )"
					fi
				) &
			fi
			;;
		update )
			if [[ -e /srv/http/data/system/updating ]] && ! mpc | grep -q '^Updating'; then
				/srv/http/bash/cmd-list.sh
			fi
			;;
	esac
done
