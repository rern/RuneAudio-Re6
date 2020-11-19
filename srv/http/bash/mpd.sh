#!/bin/bash

dirsystem=/srv/http/data/system

# convert each line to each args
readarray -t args <<< "$1"

pushRefresh() {
	[[ ! -e /srv/http/data/shm/datarestore ]] && curl -s -X POST http://127.0.0.1/pub?id=refresh -d '{ "page": "mpd" }'
}
restartMPD() {
	[[ ! -e /srv/http/data/shm/datarestore ]] && /srv/http/bash/mpd-conf.sh
}

case ${args[0]} in

amixer )
	amixer -c ${args[1]}scontents \
		| grep -A2 'Simple mixer control' \
		| grep -v 'Capabilities' \
		| tr -d '\n' \
		| sed 's/--/\n/g' \
		| grep 'Playback channels' \
		| sed "s/.*'\(.*\)',\(.\) .*/\1 \2/; s/ 0$//" \
		| awk '!a[$0]++'
	;;
audiooutput )
	aplayname=${args[1]}
	card=${args[2]}
	output=${args[3]}
	mixer=${args[4]}
	[[ ${output:0:7} == WM5102 ]] && /srv/http/bash/mpd-wm5102.sh $card ${output/*-} &> /dev/null
	if [[ $aplayname != $( cat /srv/http/data/shm/usbdac 2> /dev/null ) ]]; then
		echo $aplayname > $dirsystem/audio-aplayname
		echo $output > $dirsystem/audio-output
	fi
	sed -i -e '/output_device = / s/".*"/"hw:'$card'"/
	' -e '/mixer_control_name = / s/".*"/"'$mixer'"/
	' /etc/shairport-sync.conf
	systemctl try-restart shairport-sync shairport-meta
	pushRefresh
	;;
autoupdate )
	if [[ ${args[1]} == true ]]; then
		sed -i '1 i\auto_update          "yes"' /etc/mpd.conf
		touch $dirsystem/mpd-autoupdate
	else
		sed -i '/^auto_update/ d' /etc/mpd.conf
		rm -f $dirsystem/mpd-autoupdate
	fi
	restartMPD
	pushRefresh
	;;
buffer )
	if [[ ${args[1]} == true ]]; then
		touch $dirsystem/mpd-buffer
	else
		sed -i '/^audio_buffer_size/ d' /etc/mpd.conf
		rm -f $dirsystem/mpd-buffer
	fi
	restartMPD
	pushRefresh
	;;
bufferset )
	buffer=${args[1]}
	sed -i -e '/^audio_buffer_size/ d
' -e '1 i\audio_buffer_size    "'$buffer'"' /etc/mpd.conf
	echo $buffer > $dirsystem/mpd-bufferset
	;;
bufferoutput )
	if [[ ${args[1]} == true ]]; then
		touch $dirsystem/mpd-bufferoutput
	else
		sed -i '/^max_output_buffer_size/ d' /etc/mpd.conf
		rm -f $dirsystem/mpd-bufferoutput
	fi
	restartMPD
	pushRefresh
	;;
bufferoutputset )
	buffer=${args[1]}
	sed -i -e '/^max_output_buffer_size/ d
' -e '1 i\max_output_buffer_size "'$buffer'"' /etc/mpd.conf
	echo $buffer > $dirsystem/mpd-bufferoutputset
	;;
count )
	albumartist=$( mpc list albumartist | awk NF | wc -l )
	composer=$( mpc list composer | awk NF | wc -l )
	genre=$( mpc list genre | awk NF | wc -l )
	count="$count $( mpc stats | head -n3 | awk '{print $2,$4,$6}' )"

	data='
		  "album"       : '$( echo $count | cut -d' ' -f2 )'
		, "albumartist" : '$albumartist'
		, "artist"      : '$( echo $count | cut -d' ' -f1 )'
		, "composer"    : '$composer'
		, "coverart"    : '$( ls -1q /srv/http/data/coverarts | wc -l )'
		, "date"        : '$( mpc list date | awk NF | wc -l )'
		, "genre"       : '$genre'
		, "nas"         : '$( mpc ls NAS 2> /dev/null | wc -l )'
		, "sd"          : '$( mpc ls SD 2> /dev/null | wc -l )'
		, "song"        : '$( echo $count | cut -d' ' -f3 )'
		, "usb"         : '$( mpc ls USB 2> /dev/null | wc -l )'
		, "webradio"    : '$( ls -U /srv/http/data/webradios/* 2> /dev/null | wc -l )
	mpc | grep -q Updating && data+=', "updating_db":1'
	echo {$data}
	echo $albumartist $composer $genre > /srv/http/data/system/mpddb
	;;
crossfade )
	if [[ ${args[1]} == true ]]; then
		touch $dirsystem/mpd-crossfade
	else
		mpc crossfade 0
		rm -f $dirsystem/mpd-crossfade
	fi
	pushRefresh
	;;
crossfadeset )
	crossfade=${args[1]}
	mpc crossfade $crossfade
	echo $crossfade > $dirsystem/mpd-crossfadeset
	;;
custom )
	enable=${args[1]}
	if [[ $enable == true ]]; then
		[[ -e $dirsystem/mpd-custom-global ]] && /srv/http/bash/mpd.sh customset$'\n'$( cat $dirsystem/mpd-custom-global )
		touch $dirsystem/mpd-custom
	else
		sed -i '/ #custom$/ d' /etc/mpd.conf
		rm -f $dirsystem/mpd-custom
	fi
	restartMPD
	pushRefresh
	;;
customset )
	global=${args[1]}
	output=${args[2]}
	file=$dirsystem/mpd-custom
	touch $file
	sed -i '/ #custom$/ d' /etc/mpd.conf
	if [[ -n $global ]]; then
		echo "$global" > $file-global
		global=$( echo "$global" | tr ^ '\n' | sed 's/$/ #custom/' )
		sed -i "/^user/ a$global" /etc/mpd.conf
	fi
	if [[ -n $output ]]; then
		echo "$output" > $file-output
	else
		rm -f $file-output
	fi
	restartMPD
	pushRefresh
	;;
dop )
	dop=${args[1]}
	output=${args[2]}
	if [[ $dop == true ]]; then
		touch "$dirsystem/mpd-dop-$output"
	else
		rm -f "$dirsystem/mpd-dop-$output"
	fi
	restartMPD
	pushRefresh
	;;
ffmpeg )
	if [[ ${args[1]} == true ]]; then
		sed -i '/ffmpeg/ {n; s/".*"/"yes"/}' /etc/mpd.conf
		touch $dirsystem/mpd-ffmpeg
	else
		sed -i '/ffmpeg/ {n; s/".*"/"no"/}' /etc/mpd.conf
		rm -f $dirsystem/mpd-ffmpeg
	fi
	restartMPD
	pushRefresh
	;;
filetype )
	type=$( mpd -V | grep '\[ffmpeg' | sed 's/.*ffmpeg. //; s/ rtp.*//' | tr ' ' '\n' | sort )
	for i in {a..z}; do
		line=$( grep ^$i <<<"$type" | tr '\n' ' ' )
		[[ -n $line ]] && list+=${line:0:-1}'<br>'
	done
	echo "${list:0:-4}"
	;;
manualconf )
	if [[ ${args[1]} == true ]]; then
		cat /etc/mpd.conf | tee $dirsystem/mpd-manualconf
	else
		rm -f $dirsystem/mpd-manualconf
	fi
	pushRefresh
	;;
manualconfsave )
	printf '%s\n' "${args[@]:1}" | tee /etc/mpd.conf $dirsystem/mpd-manualconf
	restartMPD
	pushRefresh
	;;
mixerhw )
	output=${args[1]}
	mixer=${args[2]}
	hwmixer=${args[3]}
	aplayname=${args[4]}
	sed -i '/'$output'/,/}/ s/\(mixer_control \+"\).*/\1"'$mixer'"/' /etc/mpd.conf
	sed -i '/mixer_control_name = / s/".*"/"'$mixer'"/' /etc/shairport-sync.conf
	if [[ $hwmixer == auto ]]; then
		rm -f "/srv/http/data/system/mpd-hwmixer-$aplayname"
	else
		echo $hwmixer > "/srv/http/data/system/mpd-hwmixer-$aplayname"
	fi
	systemctl try-restart shairport-sync shairport-meta
	restartMPD
	pushRefresh
	;;
mixerset )
	mixer=${args[1]}
	output=${args[2]}
	card=${args[3]}
	control=${args[4]}
	volumenone=0
	if [[ $mixer == none ]]; then
		[[ -n $control ]] && amixer -c $card sset $control 0dB
		volumenone=1
	fi
	if [[ $mixer == hardware ]]; then
		rm -f "$dirsystem/mpd-mixertype-$output"
	else
		echo $mixer > "$dirsystem/mpd-mixertype-$output"
	fi
	restartMPD
	pushRefresh
	curl -s -X POST http://127.0.0.1/pub?id=volumenone -d '{ "pvolumenone": "'$volumenone'" }'
	;;
normalization )
	if [[ ${args[1]} == true ]]; then
		sed -i '/^user/ a\volume_normalization "yes"' /etc/mpd.conf
		touch $dirsystem/mpd-normalization
	else
		sed -i '/^volume_normalization/ d' /etc/mpd.conf
		rm -f $dirsystem/mpd-normalization
	fi
	restartMPD
	pushRefresh
	;;
novolume )
	sed -i -e '/volume_normalization/ d
	' -e '/^replaygain/ s/".*"/"off"/
	' /etc/mpd.conf
	echo none > "$dirsystem/mpd-mixertype-${args[1]}"
	mpc crossfade 0
	rm -f $dirsystem/{mpd-crossfade,mpd-replaygain,mpd-normalization}
	restartMPD
	pushRefresh
	curl -s -X POST http://127.0.0.1/pub?id=volumenone -d '{ "pvolumenone": "1" }'
	;;
replaygain )
	if [[ ${args[1]} == true ]]; then
		touch $dirsystem/mpd-replaygain
	else
		sed -i '/^replaygain/ s/".*"/"off"/' /etc/mpd.conf
		rm -f $dirsystem/mpd-replaygain
	fi
	restartMPD
	pushRefresh
	;;
replaygainset )
	replaygain=${args[1]}
	sed -i '/^replaygain/ s/".*"/"'$replaygain'"/' /etc/mpd.conf
	echo $replaygain $dirsystem/mpd-replaygainset
	;;
restart )
	restartMPD
	pushRefresh
	;;
soxr )
	if [[ ${args[1]} == true ]]; then
		sed -i -e '/quality/,/}/ d
' -e "/soxr/ r $dirsystem/mpd-soxrset
" /etc/mpd.conf
		touch $dirsystem/mpd-soxr
	else
		sed -i -e '/quality/,/}/ d
' -e '/soxr/ a\
	quality        "very high"\
}
' /etc/mpd.conf
		rm -f $dirsystem/mpd-soxr
	fi
	restartMPD
	pushRefresh
	;;
soxrset )
	echo '\tquality        "custom"
	\tprecision      "'${args[1]}'"
	\tphase_response "'${args[2]}'"
	\tpassband_end   "'${args[3]}'"
	\tstopband_begin "'${args[4]}'"
	\tattenuation    "'${args[5]}'"
	\tflags          "'${args[6]}'"
}' > $dirsystem/mpd-soxrset
		sed -i -e '/quality/,/}/ d
' -e "/soxr/ r $dirsystem/mpd-soxrset
" /etc/mpd.conf
	restartMPD
	pushRefresh
	;;

esac
