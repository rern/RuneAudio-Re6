#!/bin/bash

for pid in $( pgrep shairport-sync ); do
	ionice -c 0 -n 0 -p $pid &> /dev/null 
	renice -n -19 -p $pid &> /dev/null
done

dirtmp=/srv/http/data/shm

cat /tmp/shairport-sync-metadata | while read line; do
	# remove Artist+Genre line
	[[ $line =~ 'encoding="base64"' || $line =~ '<code>'.*'<code>' ]] && continue
	
	# var: (none) - get matched hex code line
	[[ $line =~ '>61736172<' ]] && code=Artist   && continue
	[[ $line =~ '>6d696e6d<' ]] && code=Title    && continue
	[[ $line =~ '>6173616c<' ]] && code=Album    && continue
	[[ $line =~ '>50494354<' ]] && code=coverart && continue
	[[ $line =~ '>70726772<' ]] && code=Time     && timestamp=$( date +%s%3N ) && continue
	[[ $line =~ '>70766f6c<' ]] && code=volume   && continue
	
	# var: code - next line if no code yet
	[[ -z $code ]] && continue
	
	base64=${line/<\/data><\/item>}
	base64=$( echo $base64 | tr -d '\000' ) # remove null bytes
	# null or not base64 string - reset code= and next line
	if [[ -z $base64 || ! $base64 =~ ^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$ ]]; then
		code= # reset code= and start over
		continue
	fi
	
	# var: code base64 - make json for curl
	if [[ $code == coverart ]]; then
		base64 -d <<< $base64 > $dirtmp/airplay-coverart.jpg
		data=/data/shm/airplay-coverart.$( date +%s ).jpg
		curl -s -X POST http://127.0.0.1/pub?id=airplay -d '{"coverart":"'$data'"}'
	else
		data=$( echo $base64 | base64 --decode 2> /dev/null )
		if [[ $code == Time ]]; then # format: start/elapsed/end @44100
			start=${data/\/*}
			current=$( echo $data | cut -d/ -f2 )
			end=${data/*\/}
			data=$(( ( end - start + 22050 ) / 44100 ))
			
			elapsedms=$( awk "BEGIN { printf \"%.0f\n\", $(( current - start )) / 44.1 }" )
			(( $elapsedms > 0 )) && elapsed=$(( ( elapsedms + 500 ) / 1000 )) || elapsed=0
			curl -s -X POST http://127.0.0.1/pub?id=airplay -d '{"elapsed":'$elapsed'}'
			
			starttime=$(( timestamp - elapsedms ))
			echo $starttime > $dirtmp/airplay-start
		elif [[ $code == volume ]]; then # format: airplay/current/limitH/limitL
			airplayvolume=${data/,*} # -30:0% - 0:100%
			data=$(( ( 30 + $airplayvolume + 1500 ) / 30 * 100 ))
			echo $data > $dirtmp/airplay-volume
		fi
		echo $data > $dirtmp/airplay-$code
		
		[[ ' start Time volume ' =~ " $code " ]] && payload='"'$code'":'$data || payload='"'$code'":"'${data//\"/\\\"}'"'
		
		curl -s -X POST http://127.0.0.1/pub?id=airplay -d "{$payload}"
	fi
	code= # reset code= and start over
done
