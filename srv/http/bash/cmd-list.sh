#!/bin/bash

# Flags: 'updating', 'listing', 'wav'
#
#  - Use only `updating` flag from start to finish.
#  - 'wav' flag - optional: Take times, even more on NAS
#  - Resume on boot:
#    - 'updating' flag for resume `mpc update`
#    - 'listing' flag for resume without `mpc update`

dirdata=/srv/http/data
diraddons=$dirdata/addons
dirmpd=$dirdata/mpd
dirsystem=$dirdata/system

touch $dirsystem/listing

[[ $( ls /mnt/MPD/NAS ) ]] && nas=1

albumlist() {
	album_artist_file=$( mpc -f '%album%^^[%albumartist%|%artist%]^^%file%' listall \
		| awk -F'/[^/]*$' 'NF && !/^\^/ && !a[$0]++ {print $1}' \
		| sort -u )
	[[ -z $album_artist_file ]] && mpdbuffer
}
mpdbuffer() {
	buffer=$( awk -F '"' '/max_output_buffer_size/ {print $2}' )
	[[ -z $buffer ]] && buffer=8192
	buffer=$(( buffer + 8192 ))
	if (( $buffer > 65536 )); then # 8 x 8192
		notify '{"title":"Library Database","text":"Too many music files!<br>No list in Album.","icon":"library"}'
		exit
	fi
	
	sed -i -e '/max_output_buffer_size/ d
' -e '/music_directory/ i\max_output_buffer_size "'$buffer'"
' /etc/mpd.conf
	systemctl restart mpd
	albumlist
	[[ -n $album_artist_file ]] && echo $buffer > $dirsystem/outputbuffer
}
notify() {
	[[ -n $nas ]] && curl -s -X POST http://127.0.0.1/pub?id=notify -d "$1"
}

##### normal list #############################################
albumlist

##### wav list #############################################
# mpd not read *.wav albumartist
if [[ ! -e $dirsystem/wav ]]; then
	if [[ -e $dirmpd/albumwav ]]; then
		albumwav=$( cat $dirmpd/albumwav )
		readarray -t dirwav <<< "$( sed 's/.*\^//' <<< "$albumwav" )"
		for dir in "${dirwav[@]}"; do # remove duplicate directories
			album_artist_file=$( sed "\|$dir$| d" <<< "$album_artist_file" )
		done
		album_artist_file+=$'\n'"$albumwav"
	fi
else
	notify '{"title":"Wave files - Album artists","text":"Query ...","icon":"file-wave blink","delay":-1}'
	dirwav=$( find /mnt/MPD -type f -name *.wav  -printf '%h\n' | sort -u )
	if [[ -n $dirwav ]]; then
		readarray -t dirwav <<< "$dirwav"
		notify '{"title":"Wave files - Album artists","text":"'${#dirwav[@]}' *.wav in Library ...","icon":"file-wave"}'
		for dir in "${dirwav[@]}"; do
			[[ -e "$dir/"*.cue ]] && continue
			
			dirparent=$( dirname "$dir" )
			if [[ -e "$dirparent/.mpdignore" ]]; then
				readarray -t mpdignore <<< "$( cat "$dirparent/.mpdignore" )"
				for dirignore in "${mpdignore[@]}"; do
					[[ "$dirparent/$dirignore" == "$dir" ]] && continue 2
				done
			fi
			file=$( ls "$dir"/*.wav | head -1 )
			kid=$( kid3-cli -c 'get album' -c 'get albumartist' -c 'get artist' "$file" )
			if [[ -n $kid ]]; then
				album_artist_file=$( sed "\|${dir: 9}$| d" <<< "$album_artist_file" )
				albumwav+=$'\n'$( echo "$kid" \
					| head -2 \
					| awk 1 ORS='^^' \
					| sed "s|$|${dir:9}|" )
			fi
			if [[ -n $albumwav ]]; then
				album_artist_file+=$albumwav
				echo "${albumwav: 1}" > $dirmpd/albumwav
			fi
		done
	fi
	rm $dirsystem/wav
fi
album=$( echo "$album_artist_file" | grep . | sort -uf | tee $dirmpd/album | wc -l )
(( $album > 0 )) && php /srv/http/bash/cmd-listsort.php $dirmpd/album

for mode in albumartist artist composer genre date; do
	printf -v $mode '%s' $( mpc list $mode | grep . | awk '{$1=$1};1' | tee $dirmpd/$mode | wc -l )
	(( $mode > 0 )) && php /srv/http/bash/cmd-listsort.php $dirmpd/$mode
done
##### count #############################################
for mode in NAS SD USB; do
	printf -v $mode '%s' $( mpc ls $mode 2> /dev/null | wc -l )
done
song=$( mpc stats | awk '/^Songs/ {print $NF}' )
webradio=$( ls -1q $dirdata/webradios | wc -l )
counts='
  "album"       : '$album'
, "albumartist" : '$albumartist'
, "artist"      : '$artist'
, "composer"    : '$composer'
, "date"        : '$date'
, "genre"       : '$genre'
, "nas"         : '$NAS'
, "sd"          : '$SD'
, "usb"         : '$USB'
, "song"        : '$song'
, "webradio"    : '$webradio
echo {$counts} | jq . > $dirmpd/counts
curl -s -X POST http://127.0.0.1/pub?id=mpdupdate -d "{$counts}"
chown -R mpd:audio $dirmpd
rm -f $dirsystem/{updating,listing}
