#!/bin/bash

dirbash=/srv/http/bash
dirdata=/srv/http/data
diraddons=$dirdata/addons
dirmpd=$dirdata/mpd
dirsystem=$dirdata/system
dirtmp=$dirdata/shm
dirwebradios=$dirdata/webradios
flag=$dirtmp/flag
flagpladd=$dirtmp/flagpladd

# convert each line to each args
readarray -t args <<< "$1"

gifNotify() {
	pushstream notify '{"title":"Thumbnail","text":"Resize animated GIF ...","icon":"coverart blink","delay":-1}'
}
gifThumbnail() {
	type=$1
	source=$2
	target=$3
	imgwh=( $( gifsicle -I "$source" | awk 'NR < 3 {print $NF}' ) )
	[[ ${imgwh[0]} == images ]] && animated=1
	case $type in
		bookmark )
			rm -f "${target:0:-4}".*
			[[ -n $animated ]] && (( ${imgwh[1]/x*} > 200 || ${imgwh[1]/*x} > 200 )) && gifNotify
			gifsicle -O3 --resize-fit 200x200 "$source" > "$target"
			;;
		coverart )
			dir=$( dirname "$target" )
			rm -f "$dir/cover".*.backup "$dir/coverart".* "$dir/thumb".*
			coverfile=$( ls "$dir/cover".* | head -1 )
			[[ -e $coverfile ]] && mv -f "$coverfile" "$coverfile.backup"
			[[ -n $animated ]] && gifNotify
			gifsicle -O3 --resize-fit 1000x1000 "$source" > "$target"
			gifsicle -O3 --resize-fit 200x200 "$source" > "$dir/coverart.gif"
			gifsicle -O3 --resize-fit 80x80 "$source" > "$dir/thumb.gif"
			;;
		webradio )
			filenoext=${target:0:-4}
			rm -f $filenoext.* $filenoext-thumb.*
			[[ -n $animated ]] && gifNotify
			gifsicle -O3 --resize-fit 200x200 $source > $target
			gifsicle -O3 --resize-fit 80x80 $source > $filenoext-thumb.gif
			;;
	esac
	coverfile=${target:9:-4}
	coverfile=$( php -r "echo rawurlencode( '${coverfile//\'/\\\'}' );" )
	pushstream coverart '{"url":"'$coverfile.$( date +%s ).gif'","type":"'$type'"}'
}
jpgThumbnail() {
	type=$1
	source=$2
	target=$3
	case $type in
		bookmark )
			rm -f "${target:0:-4}".*
			cp -f "$source" "$target"
			;;
		coverart )
			dir=$( dirname "$target" )
			rm -f "$dir/cover".*.backup "$dir/coverart".* "$dir/thumb".*
			coverfile=$( ls "$dir/cover".* | head -1 )
			[[ -e $coverfile ]] && mv -f "$coverfile" "$coverfile.backup"
			cp -f "$source" "$target" # already resized from client
			convert "$source" -thumbnail 200x200\> -unsharp 0x.5 "$dir/coverart.jpg"
			convert "$dir/coverart.jpg" -thumbnail 80x80\> -unsharp 0x.5 "$dir/thumb.jpg"
			;;
		webradio )
			filenoext=${target:0:-4}
			rm -f $filenoext.* $filenoext-thumb.*
			cp -f $source $target
			convert $source -thumbnail 80x80\> -unsharp 0x.5 $filenoext-thumb.jpg
			;;
	esac
	[[ $type == coverart ]] && coverfile=${target:0:-4} || coverfile=${target:9:-4}
	coverfile=$( php -r "echo rawurlencode( '${coverfile//\'/\\\'}' );" )
	pushstream coverart '{"url":"'$coverfile.$( date +%s ).jpg'","type":"'$type'"}'
}
pladdPlay() {
	pushstreamPlaylist
	rm -f $flagpladd
	if [[ ${1: -4} == play ]]; then
		sleep $2
		touch $flag
		mpc play $pos
	fi
	pushstreamStatus
}
pladdPosition() {
	touch $flagpladd
	if [[ ${1:0:7} == replace ]]; then
		mpc clear
		pos=1
	else
		pos=$(( $( mpc playlist | wc -l ) + 1 ))
	fi
}
pushstream() {
	curl -s -X POST http://127.0.0.1/pub?id=$1 -d "$2"
}
pushstreamPackage() {
	pushstream package '{"pkg":"'$1'", "start":'$2',"enable":'$3' }'
}
pushstreamPlaylist() {
	pushstream playlist "$( php /srv/http/mpdplaylist.php current )"
	rm -f $flagpladd
}
pushstreamStatus() {
	status=$( $dirbash/status.sh )
	pushstream mpdplayer "$status"
	rm -f $flag
	if [[ -e /srv/http/data/system/lcdchar ]]; then
		killall lcdchar.py &> /dev/null
		readarray -t data <<< "$( echo "$status" | jq -r '.Artist, .Title, .Album, .elapsed, .Time, .state' )"
		/srv/http/bash/lcdchar.py "${data[@]}" &
	fi
}
pushstreamVolume() {
	pushstream volume '{"type":"'$1'", "val":'$2' }'
}
randomfile() {
	dir=$( cat $dirmpd/album | shuf -n 1 | cut -d^ -f7 )
	mpcls=$( mpc ls "$dir" )
	file=$( echo "$mpcls" | shuf -n 1 )
	echo $mpcls | grep -q .cue$ && file="${file%.*}.cue"
	if [[ ${file: -4} == .cue ]]; then
		plL=$(( $( grep '^\s*TRACK' "/mnt/MPD/$file" | wc -l ) - 1 ))
		range=$( shuf -i 0-$plL -n 1 )
		mpc --range=$range load "$file"
	else
		mpc add "$file"
	fi
}
urldecode() { # for webradio url to filename
	: "${*//+/ }"
	echo -e "${_//%/\\x}"
}
volumeSet() {
	current=$1
	target=$2
	diff=$(( $target - $current ))
	if (( -10 < $diff && $diff < 10 )); then
		mpc volume $target
	else # increment
		pushstream volume '{"disable":true}'
		(( $diff > 0 )) && incr=5 || incr=-5
		for i in $( seq $current $incr $target ); do
			mpc volume $i
			sleep 0.2
		done
		(( $i != $target )) && mpc volume $target
		pushstream volume '{"disable":false}'
	fi
}

case ${args[0]} in

addonsclose )
	script=${args[1]}
	alias=${args[2]}
	killall $script wget pacman &> /dev/null
	rm -f /var/lib/pacman/db.lck /srv/http/*.zip $diraddons/$alias /usr/local/bin/uninstall_$alias.sh
	;;
addonslist )
	wget https://github.com/rern/RuneAudio_Addons/raw/master/addons-list.json -qO $diraddons/addons-list.json
	[[ $? != 0 ]] && echo -1 && exit
	
	bash=$( jq -r .push.bash $diraddons/addons-list.json ) # check condition - wget if necessary
	if [[ -n $bash ]]; then
		eval "$bash"
		[[ $? != 0 ]] && exit
	fi
	
	url=$( jq -r .push.url $diraddons/addons-list.json )
	[[ -n $url ]] && wget $url -qO - | sh
	;;
addonsupdate )
	[[ -z ${args[1]} ]] && wget https://github.com/rern/RuneAudio_Addons/raw/master/addons-list.json -qO $diraddons/addons-list.json
	installed=$( ls "$diraddons" | grep -v addons-list )
	count=0
	for addon in $installed; do
		verinstalled=$( cat $diraddons/$addon )
		if (( ${#verinstalled} > 1 )); then
			verlist=$( jq -r .$addon.version $diraddons/addons-list.json )
			[[ $verinstalled != $verlist ]] && (( count++ ))
		fi
	done
	(( $count )) && echo $count > $diraddons/update || rm -f $diraddons/update
	;;
bookmarkreset )
	path=${args[1]}
	rm -f "/mnt/MPD/$path/"{coverart,thumb}.*
	;;
bookmarkthumb )
	mpdpath=${args[1]}
	coverartfile=$( ls "/mnt/MPD/$mpdpath/coverart".* )
	echo ${coverartfile: -3} # ext
	;;
color )
	cmd=${args[1]}
	file=$dirsystem/color
	if [[ $cmd == reset ]]; then
		rm $file
	elif [[ -n $cmd && $cmd != color ]]; then # omit call from addons-functions.sh / backup-restore.sh
		echo $cmd > $file
	fi
	if [[ -e $file ]]; then
		hsl=( $( cat $file ) )
		h=${hsl[0]}; s=${hsl[1]}; l=${hsl[2]}
	else
		h=200; s=100; l=35
	fi
	hs="$h,$s%,"
	hsg="$h,3%,"

sed -i "
 s|\(--cml: *hsl\).*;|\1(${hs}$(( l + 5 ))%);|
  s|\(--cm: *hsl\).*;|\1(${hs}$l%);|
 s|\(--cma: *hsl\).*;|\1(${hs}$(( l - 5 ))%);|
 s|\(--cmd: *hsl\).*;|\1(${hs}$(( l - 15 ))%);|
s|\(--cg75: *hsl\).*;|\1(${hsg}75%);|
s|\(--cg60: *hsl\).*;|\1(${hsg}60%);|
 s|\(--cgl: *hsl\).*;|\1(${hsg}40%);|
  s|\(--cg: *hsl\).*;|\1(${hsg}30%);|
 s|\(--cga: *hsl\).*;|\1(${hsg}20%);|
 s|\(--cgd: *hsl\).*;|\1(${hsg}10%);|
" /srv/http/assets/css/colors.css
	pushstream reload 1
	;;
count )
	count
	;;
coverartreset )
	coverfile=${args[1]}
	mpdpath=${args[2]}
	artist=${args[3]}
	album=${args[4]}
	dir=$( dirname "$coverfile" )
	rm -f "$coverfile" "$dir/coverart".* "$dir/thumb".*
	backupfile=$( ls -p "$dir"/*.backup | head -1 )
	if [[ -e $backupfile ]]; then
		restorefile=${backupfile%%.backup}
		ext=${restorefile: -3}
		if [[ $ext != gif ]]; then
			jpgThumbnail coverart "$backupfile" "$restorefile"
		else
			gifThumbnail coverart "$backupfile" "$restorefile"
		fi
		rm "$backupfile"
	fi
	url=$( $dirbash/status-coverart.sh "$mpdpath
$artist
$album" )
	echo $url
	;;
coverartradioreset )
	coverfile=${args[1]}
	rm -f "$coverfile".* "$coverfile-thumb".*
	pushstream coverart '{"url":"'$coverfile'","type":"webradioreset"}'
	;;
coversave )
	source=${args[1]}
	path=${args[2]}
	coverfile="$path/cover.jpg"
	jpgThumbnail coverart "$source" "$coverfile"
	;;
displayget )
	output=$( cat $dirsystem/usbdac 2> /dev/null )
	[[ -z $output ]] && output=$( cat $dirsystem/audio-output )
	volume=$( sed -n "/$output/,/^}/ p" /etc/mpd.conf \
		| awk -F '\"' '/mixer_type/ {print $2}' )
	data=$( sed '$ d' $dirsystem/display )
	data+='
, "color"      : "'$( cat $dirsystem/color 2> /dev/null || echo '200 100 35' )'"
, "order"      : '$( cat $dirsystem/order 2> /dev/null )'
, "volumenone" : '$( [[ $volume == none ]] && echo true || echo false )'
}'
echo "$data"
	;;
gpio )
	onoff=${args[1]}
	if [[ $onoff == true ]]; then
		$dirbash/gpio.py on
	else
		$dirbash/gpio.py off
	fi
	;;
gpioset )
	echo ${args[1]} | jq . > $dirsystem/gpio.json
	;;
gpiotimerreset )
	awk '/timer/ {print $NF}' $dirsystem/gpio.json > $dirtmp/gpiotimer
	pushstream gpio '{"state":"RESET"}'
	;;
ignoredir )
	touch $dirsystem/updating
	path=${args[1]}
	dir=$( basename "$path" )
	mpdpath=$( dirname "$path" )
	echo $dir >> "/mnt/MPD/$mpdpath/.mpdignore"
	pushstream mpdupdate 1
	mpc update "$mpdpath" #1 get .mpdignore into database
	mpc update "$mpdpath" #2 after .mpdignore was in database
	;;
randomfile )
	randomfile
	;;
librandom )
	enable=${args[1]}
	if [[ $enable == false ]]; then
		rm -f $dirsystem/librandom
	else
		mpc random 0
		plL=$( mpc playlist | wc -l )
		randomfile # 1st track
		randomfile # 2nd track
		randomfile # 3rd track
		touch $dirsystem/librandom
		sleep 1
		mpc play $(( plL + 1 ))
	fi
	pushstream option '{ "librandom": '$enable' }'
	pushstream playlist "$( php /srv/http/mpdplaylist.php current )"
	;;
list )
	list
	;;
lyrics )
	artist=${args[1]}
	title=${args[2]}
	cmd=${args[3]}
	lyrics=${args[4]}
	name="$artist - $title"
	name=${name//\/}
	
	lyricsfile="$dirdata/lyrics/${name,,}.txt"
	if [[ $cmd == local ]]; then
		[[ -e $lyricsfile ]] && echo "$title^^$( cat "$lyricsfile" )" # return with title for display
	elif [[ $cmd == save ]]; then
		echo -e "${lyrics//^/\\n}" > "$lyricsfile" # split at ^ delimiter to lines
	elif [[ $cmd == delete ]]; then
		rm "$lyricsfile"
	else
		artist=$( echo $artist | sed 's/^A \|^The \|\///g' )
		title=${title//\/}
		query=$( echo $artist/$title \
					| tr -d " '\-\"\!*\(\);:@&=+$,?#[]." )
		lyrics=$( curl -s -A firefox https://www.azlyrics.com/lyrics/${query,,}.html )
		if [[ -n $lyrics ]]; then
			echo "$lyrics" \
				| sed -n '/id="cf_text_top"/,/id="azmxmbanner"/ p' \
				| sed -e '/^\s*$/ d' -e '/\/div>/,/<br>/ {N;d}' -e 's/<br>//' -e 's/&quot;/"/g' \
				| grep -v '^<' \
				| tee "$lyricsfile"
		fi
	fi
	;;
mpcoption )
	option=${args[1]}
	onoff=${args[2]}
	mpc $option $onoff
	pushstream option '{"'$option'":'$onoff'}'
	;;
mpcplayback )
	touch $flag
	command=${args[1]}
	pos=${args[2]}
	mpc $command $pos
	# webradio start - status.sh > 'file:' missing
	if [[ $( mpc current -f %file% | cut -c1-4 ) == http ]]; then
		sleep 0.6
		touch $dirtmp/webradio
	fi
	pushstreamStatus
	;;
mpcprevnext )
	touch $flag
	command=${args[1]}
	current=$(( ${args[2]} + 1 ))
	length=${args[3]}
	mpc | grep -q '^\[playing\]' && playing=1
	
	if mpc | grep -q 'random: on'; then
		pos=$( shuf -n 1 <( seq $length | grep -v $current ) )
		mpc play $pos
	else
		if [[ $command == next ]]; then
			(( $current != $length )) && mpc play $(( current + 1 )) || mpc play 1
			mpc | grep -q 'consume: on' && mpc del $current
			[[ -e $dirsystem/librandom ]] && /srv/http/bash/cmd.sh randomfile
		else
			(( $current != 1 )) && mpc play $(( current - 1 )) || mpc play $length
		fi
	fi
	if [[ -z $playing ]]; then
		mpc stop
	else
		[[ $( mpc current -f %file% | cut -c1-4 ) == http ]] && sleep 0.6 || sleep 0.05 # suppress multiple player events
	fi
	pushstreamStatus
	;;
mpcseek )
	touch $flag
	seek=${args[1]}
	pause=${args[2]}
	if [[ -n $pause ]]; then
		mpc play
		mpc pause
		mpc seek $seek
		state=pause
	else
		mpc seek $seek
	fi
	pushstream seek '{"elapsed":'$seek',"state":"'$state'"}'
	rm -f $flag
	;;
mpcupdate )
	[[ ${args[1]} == true ]] && touch $dirsystem/wav
	path=${args[2]}
	pushstream mpdupdate 1
	if [[ $path != rescan ]]; then
		echo $path > $dirsystem/updating
		mpc update "$path"
	else
		echo rescan > $dirsystem/updating
		mpc rescan
	fi
	;;
nicespotify )
	for pid in $( pgrep spotifyd ); do
		ionice -c 0 -n 0 -p $pid &> /dev/null 
		renice -n -19 -p $pid &> /dev/null
	done
	;;
packageenable )
	pkg=${args[1]}
	enable=${args[2]}
	systemctl start $pkg
	pushstreamPackage $pkg true $enable
	;;
packageset )
	pkg=${args[1]}
	start=${args[2]}
	enable=${args[3]}
	[[ $start == true ]] && systemctl start $pkg || systemctl stop $pkg
	[[ $enable == true ]] && systemctl enable $pkg || systemctl disable $pkg
	pushstreamPackage $pkg $start $enable
	;;
pladd )
	item=${args[1]}
	cmd=${args[2]}
	delay=${args[3]}
	pladdPosition $cmd
	mpc add "$item"
	pladdPlay $cmd $delay
	;;
plcrop )
	touch $flag
	if mpc | grep -q playing; then
		mpc crop
	else
		mpc play
		mpc crop
		mpc stop
	fi
	touch $flagpladd
	systemctl -q is-active libraryrandom && randomfile
	pushstreamStatus
	pushstreamPlaylist
	;;
plfindadd )
	if [[ ${args[1]} != multi ]]; then
		type=${args[1]}
		string=${args[2]}
		cmd=${args[3]}
		pladdPosition $cmd
		mpc findadd $type "$string"
	else
		type=${args[2]}
		string=${args[3]}
		type2=${args[4]}
		string2=${args[5]}
		cmd=${args[6]}
		pladdPosition $cmd
		mpc findadd $type "$string" $type2 "$string2"
	fi
	pladdPlay $cmd $delay
	;;
plload )
	playlist=${args[1]}
	cmd=${args[2]}
	delay=${args[3]}
	pladdPosition $cmd
	mpc load "$playlist"
	pladdPlay $cmd $delay
	;;
plloadrange )
	range=${args[1]}
	playlist=${args[2]}
	cmd=${args[3]}
	delay=${args[4]}
	pladdPosition $cmd
	mpc --range=$range load "$playlist"
	pladdPlay $cmd $delay
	;;
plls )
	dir=${args[1]}
	cmd=${args[2]}
	delay=${args[3]}
	pladdPosition $cmd
	readarray -t cuefiles <<< $( mpc ls "$dir" | grep '\.cue$' | sort -u )
	if [[ -z $cuefiles ]]; then
		mpc ls "$dir" | mpc add &> /dev/null
	else
		for cuefile in "${cuefiles[@]}"; do
			mpc load "$cuefile"
		done
	fi
	pladdPlay $cmd $delay
	;;
plorder )
	touch $flagpladd
	mpc move ${args[1]} ${args[2]}
	pushstreamPlaylist
	;;
plremove )
	pos=${args[1]}
	touch $flagpladd
	[[ -n $pos ]] && mpc del $pos || mpc clear
	pushstreamPlaylist
	pushstreamStatus
	;;
plrename )
	touch $flagpladd
	mv "$dirdata/playlists/${args[1]}" "$dirdata/playlists/${args[2]}"
	pushstreamPlaylist
	;;
plshuffle )
	touch $flagpladd
	mpc shuffle
	pushstreamPlaylist
	;;
plsimilar )
	plLprev=$( mpc playlist | wc -l )
	linesL=${#args[@]}
	[[ ${args[1]} == addplay ]] && pos=$(( $( mpc playlist | wc -l ) + 1 ))
	for (( i=1; i < linesL; i++ )); do
		artist=${args[$i]}
		(( i++ ))
		title=${args[$i]}
		[[ -z $artist || -z $title ]] && continue
		
		file=$( mpc find artist "$artist" title "$title" )
		[[ -z $file ]] && continue
		
		list+="$( mpc find artist "$artist" title "$title" )
"
	done
	touch $flagpladd
	echo "$list" | awk 'NF' | mpc add
	pushstreamPlaylist
	echo $(( $( mpc playlist | wc -l ) - plLprev ))
	if [[ -n $pos ]]; then
		touch $flag
		mpc -q play $pos
		pushstreamStatus
	fi
	;;
power )
	type=${args[1]}
	mpc stop
	[[ -e $dirtmp/gpiotimer ]] && $dirbash/gpio.py off && sleep 2
	if [[ $type == off ]]; then
		pushstream notify '{"title":"Power","text":"Off ...","icon":"power blink","delay":-1}'
	else
		pushstream notify '{"title":"Power","text":"Reboot ...","icon":"reboot blink","delay":-1}'
	fi
	$dirbash/ply-image /srv/http/assets/img/splash.png &> /dev/null
	mount | grep -q /mnt/MPD/NAS && umount -l /mnt/MPD/NAS/* &> /dev/null
	sleep 3
	[[ $type == off ]] && shutdown -h now || shutdown -r now
	;;
refreshbrowser )
	pushstream reload 1
	;;
thumbgif )
	type=${args[1]}
	source=${args[2]}
	target=${args[3]}
	gifThumbnail "$type" "$source" "$target"
	;;
thumbjpg )
	type=${args[1]}
	source=${args[2]}
	target=${args[3]}
	jpgThumbnail "$type" "$source" "$target"
	;;
volume )
	current=${args[1]}
	target=${args[2]}
	filevolumemute=$dirsystem/volumemute
	if [[ -n $target ]]; then # set
		pushstreamVolume set $target
		volumeSet $current $target
		rm -f $filevolumemute
	else
		if (( $current > 0 )); then # mute
			pushstreamVolume mute $current true
			volumeSet $current 0 false
			echo $current > $filevolumemute
		else # unmute
			target=$( cat $filevolumemute )
			pushstreamVolume unmute $target true
			volumeSet 0 $target
			rm -f $filevolumemute
		fi
	fi
	;;
volumeincrement )
	target=${args[1]}
	mpc volume $target
	pushstreamVolume set $target
	;;
webradioadd )
	name=${args[1]}
	url=$( urldecode ${args[2]} )
	filewebradio=$dirwebradios/${url//\//|}
	[[ -e $filewebradio ]] && cat $filewebradio && exit
	
	ext=${url/*.}
	if [[ $ext == m3u ]]; then
		url=$( curl -s $url | grep ^http | head -1 )
	elif [[ $ext == pls ]]; then
		url=$( curl -s $url | grep ^File | head -1 | cut -d= -f2 )
	fi
	[[ -z $url ]] && echo -1 && exit
	
	echo $name > $filewebradio
	chown http:http $filewebradio # for edit in php
	count=$(( $( jq .webradio $dirmpd/counts ) + 1 ))
	pushstream webradio $count
	sed -i 's/\("webradio": \).*/\1'$count'/' $dirmpd/counts
	;;
webradiodelete )
	url=${args[1]}
	urlname=${url//\//|}
	rm $dirwebradios/$urlname
	rm -f ${dirwebradios}img/$urlname{,-thumb}.jpg
	count=$(( $( jq .webradio $dirmpd/counts ) - 1 ))
	pushstream webradio $count
	sed -i 's/\("webradio": \).*/\1'$count'/' $dirmpd/counts
	;;
webradioedit )
	url=${args[1]}
	urlname=${url//\//|}
	newname=${args[2]}
	newurl=$( urldecode ${args[3]} )
	newurlname=${newurl//\//|}
	filewebradionew=$dirwebradios/$newurlname
	[[ $url != $newurl && -e $filewebradionew ]] && cat $filewebradionew && exit
	
	filewebradio=$dirwebradios/$urlname
	dirwebradioimg=${dirwebradios}img
	oldname=$( cat $filewebradio | head -1 )
	if [[ $oldname != $newname && $filewebradio == $filewebradionew ]]; then
		sed -i "1 c$newname" $filewebradio
		exit
	fi
	
	if [[ $oldname != $newname && $filewebradio != $filewebradionew ]]; then
		sed -e "1 c$newname" $filewebradio > $filewebradionew
		rm $filewebradio
	else
		mv $filewebradio $filewebradionew
	fi
	mv $dirwebradioimg/{$urlname,$newurlname}.jpg 
	mv $dirwebradioimg/{$urlname,$newurlname}-thumb.jpg 
	;;
	
esac
