#!/bin/bash

dirsystem=/srv/http/data/system

# convert each line to each args
readarray -t args <<< "$1"

pushRefresh() {
	curl -s -X POST http://127.0.0.1/pub?id=refresh -d '{ "page": "mpd" }'
}
restartMPD() {
	/srv/http/bash/mpd-conf.sh
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
		rm $dirsystem/mpd-autoupdate
	fi
	restartMPD
	pushRefresh
	;;
buffer )
	buffer=${args[1]}
	if [[ -n $buffer ]]; then
		sed -i -e '/^audio_buffer_size/ d
		' -e '1 i\audio_buffer_size    "'$buffer'"' /etc/mpd.conf
		echo $buffer > $dirsystem/mpd-buffer
	else
		sed -i '/^audio_buffer_size/ d' /etc/mpd.conf
		rm $dirsystem/mpd-buffer
	fi
	restartMPD
	pushRefresh
	;;
bufferoutput )
	buffer=${args[1]}
	if [[ -n $buffer ]]; then
		sed -i -e '/^max_output_buffer_size/ d
		' -e '1 i\max_output_buffer_size "'$buffer'"' /etc/mpd.conf
		echo $buffer > $dirsystem/mpd-bufferoutput
	else
		sed -i '/^max_output_buffer_size/ d' /etc/mpd.conf
		rm $dirsystem/mpd-bufferoutput
	fi
	restartMPD
	pushRefresh
	;;
crossfade )
	crossfade=${args[1]}
	if [[ -n $crossfade ]]; then
		mpc crossfade $crossfade
		echo $crossfade > $dirsystem/mpd-crossfade
	else
		mpc crossfade 0
		rm $dirsystem/mpd-crossfade
	fi
	pushRefresh
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
customdisable )
	file=$dirsystem/mpd-custom
	sed -i '/ #custom$/ d' /etc/mpd.conf
	rm $dirsystem/mpd-custom
	restartMPD
	pushRefresh
	;;
customget )
	file=$dirsystem/mpd-custom
	global=$( sed 's/^\t\| #custom$//g' $file-global | tr '\n' ^ )
	output=$( sed 's/^\t\| #custom$//g' $file-output | tr '\n' ^ )
	echo "${global:0:-1}"$'\n'"${output:0:-1}"
	;;
customset )
	global=$( printf '%s\n' "${args[@]:1:3}" | grep . | sed 's/$/ #custom/' )
	output=$( printf '%s\n' "${args[@]:4:3}" | grep . | sed 's/^/\t/; s/$/ #custom/' )
	file=$dirsystem/mpd-custom
	touch $file
	sed -i '/ #custom$/ d' /etc/mpd.conf
	if [[ -n $global ]]; then
		sed -i "/^user/ a$global" /etc/mpd.conf
		echo "$global" > $file-global
	else
		rm $file-global
	fi
	if [[ -n $output ]]; then
		echo "$output" > $file-output
	else
		rm $file-output
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
		rm "$dirsystem/mpd-dop-$output"
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
		rm $dirsystem/mpd-ffmpeg
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
		rm $dirsystem/mpd-manualconf
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
		rm "/srv/http/data/system/mpd-hwmixer-$aplayname"
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
		rm "$dirsystem/mpd-mixertype-$output"
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
		rm $dirsystem/mpd-normalization
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
	rm $dirsystem/{mpd-crossfade,mpd-replaygain,mpd-normalization}
	restartMPD
	pushRefresh
	curl -s -X POST http://127.0.0.1/pub?id=volumenone -d '{ "pvolumenone": "1" }'
	;;
replaygain )
	replaygain=${args[1]}
	if [[ -n $replaygain ]]; then
		sed -i '/^replaygain/ s/".*"/"'$replaygain'"/' /etc/mpd.conf
		echo $replaygain $dirsystem/mpd-replaygain
	else
		sed -i '/^replaygain/ s/".*"/"off"/' /etc/mpd.conf
		rm $dirsystem/mpd-replaygain
	fi
	restartMPD
	pushRefresh
	;;
restart )
	restartMPD
	pushRefresh
	;;
soxr )
	sed -i '/quality/,/}/ d' /etc/mpd.conf
	if [[ ${args[1]} == true ]]; then
		sed -i "/soxr/ r $dirsystem/mpd-soxrset" /etc/mpd.conf
	else
		sed -i '/soxr/ a\
	quality        "very high"\
}
' /etc/mpd.conf
	fi
	restartMPD
	pushRefresh
	;;
soxrset )
	sed -i -e 's/\(precision\s*"\).*/\1'${args[1]}'"/
' -e 's/\(phase_response\s*"\).*/\1'${args[2]}'"/
' -e 's/\(passband_end\s*"\).*/\1'${args[3]}'"/
' -e 's/\(stopband_begin\s*"\).*/\1'${args[4]}'"/
' -e 's/\(attenuation\s*"\).*/\1'${args[5]}'"/
' -e 's/\(flags\s*"\).*/\1'${args[6]}'"/
' $dirsystem/mpd-soxrset
		sed -i -e '/quality/,/}/ d
' -e "/soxr/ r $dirsystem/mpd-soxrset
" /etc/mpd.conf
	restartMPD
	pushRefresh
	;;

esac
