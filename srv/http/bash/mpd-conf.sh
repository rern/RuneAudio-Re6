#!/bin/bash

# remove all output the reinstate each output:
# - get devices data from 'mpd-devices.sh'
# - assign common paramters
# - mixer_type    - from file if manually set | hardware if hwmixer | software
# - mixer_control - from file if manually set | hwmixer | null
# - mixer_device  - card index
# - dop           - if set

dirsystem=/srv/http/data/system

if [[ -e $dirsystem/mpd-manualconf ]]; then
	systemctl -q is-active mpd && systemctl restart mpd || systemctl start mpd
	exit
fi

! systemctl -q is-active nginx && exit 0 # udev rule trigger on startup

pushstream() {
	curl -s -X POST http://127.0.0.1/pub?id=$1 -d "$2"
}

if [[ $1 == bt ]]; then
	# for connected by sender - not paired yet and no trust
	lines=$( bluetoothctl devices | cut -d' ' -f2 )
	echo "$lines" >> /srv/http/data/shm/bt
	readarray -t macs <<< "$lines"
	for mac in "${macs[@]}"; do
		bluetoothctl trust $mac
	done
	
	lines=$( bluetoothctl paired-devices )
	readarray -t paired <<< "$lines"
	for device in "${paired[@]}"; do
		mac=$( cut -d' ' -f2 <<< "$device" )
		(( $( bluetoothctl info $mac | grep 'Connected: yes\|Audio Sink' | wc -l ) != 2 )) && continue
		
		btoutput+='

audio_output {
	name           "'$( cut -d' ' -f3- <<< "$device" )'"
	device         "bluealsa:DEV='$mac',PROFILE=a2dp"
	type           "alsa"
	mixer_type     "software"
}'
	done
	if [[ -z $btoutput ]]; then
		pushstream refresh '{"page":"network"}' # bluetooth status
		exit # no Audio Sink bluetooth
	fi
fi
pushstream refresh '{"page":"network"}'

audiooutput=$( cat $dirsystem/audio-output )
audioaplayname=$( cat $dirsystem/audio-aplayname )
mpdfile=/etc/mpd.conf
mpdconf=$( sed '/audio_output/,/}/ d' $mpdfile ) # remove all outputs

. /srv/http/bash/mpd-devices.sh

for (( i=0; i < cardL; i++ )); do
	card=${Acard[i]}
	dop=${Adop[i]}
	hw=${Ahw[i]}
	hwmixer=${Ahwmixer[i]}
	mixermanual=${Amixermanual[i]}
	mixertype=${Amixertype[i]}
	name=${Aname[i]}
	aplayname=${Aaplayname[i]}
	
########
	mpdconf+='

audio_output {
	name           "'$name'"
	device         "'$hw'"
	type           "alsa"
	auto_resample  "no"
	auto_format    "no"
	mixer_type     "'$mixertype'"'
	
	if [[ $mixertype == hardware ]]; then # mixer_device must be card index
		if [[ -n $mixermanual ]]; then
			mixercontrol=$mixermanual
		elif [[ -n $hwmixer ]]; then
			mixercontrol=$hwmixer
		fi
########
		mpdconf+='
	mixer_control  "'$mixercontrol'"
	mixer_device   "hw:'$card'"'
		
	fi
	
	if [[ $dop == 1 ]]; then
########
		mpdconf+='
	dop            "yes"'
	
	fi
	mpdcustom=$dirsystem/mpd-custom
	customfile="$mpdcustom-output-$name"
	if [[ -e $mpdcustom && -e "$customfile" ]]; then
########
		mpdconf+="
$( cat "$customfile" | tr ^ '\n' | sed 's/^/\t/' )"
	
	fi
########
	mpdconf+='
}'
done

if systemctl -q is-active snapserver; then
	mpdconf+='

audio_output {
	type           "fifo"
	name           "Snapcast"
	path           "/tmp/snapfifo"
	format         "48000:16:2"
	mixer_type     "software"
}'
fi

if [[ -e $dirsystem/streaming ]]; then
	mpdconf+='

audio_output {
	type           "httpd"
	name           "Streaming"
	encoder        "flac"
	port           "8000"
	quality        "5.0"
	format         "44100:16:1"
	always_on      "yes"
}'
fi

[[ -n $btoutput ]] && mpdconf+=$btoutput

echo "$mpdconf" > $mpdfile

# set default card for bluetooth
echo "\
defaults.pcm.card $card
defaults.ctl.card $card" > /etc/asound.conf

systemctl restart mpd  # "restart" while not running = start + stop + start

if [[ -e $dirsystem/updating ]]; then
	path=$( cat $dirsystem/updating )
	[[ $path == rescan ]] && mpc rescan || mpc update "$path"
fi

pushstream mpdplayer "$( /srv/http/bash/status.sh )"
pushstream refresh '{"page":"mpd"}'

# udev rules - usb dac
usbdacfile=/srv/http/data/shm/usbdac
if [[ $# -gt 0 && $1 != bt ]]; then
	if [[ $1 == remove ]]; then
		name=$audiooutput
		card=$( aplay -l \
			| grep "$audioaplayname" \
			| head -1 \
			| cut -c6 )
		hwmixer=$( amixer -c $card scontents \
			| grep -B1 'pvolume' \
			| head -1 \
			| cut -d"'" -f2 )
		rm -f $usbdacfile*
	else
		name=${Aname[@]: -1} # added usb dac = last one
		card=${Acard[@]: -1}
		mixertype=${Ahwmixer[@]: -1}
		hwmixer=${Amixertype[@]: -1}
		[[ $mixertype == 'none' && -n $hwmixer ]] && amixer -c $card sset "$hwmixer" 0dB
		echo $aplayname > $usbdacfile # flag - active usb
	fi
	
	pushstream notify '{"title":"Audio Output","text":"'"$name"'","icon": "output"}'
	
	[[ $( sed -n "/$name/,/^}/ p" /etc/mpd.conf | grep mixer_type | cut -d\" -f2 ) == 'none' ]] && volumenone=true || volumenone=false
	pushstream display '{"volumenone":'$volumenone'}'
else
	aplayname=$audioaplayname
fi

if [[ -e /usr/bin/shairport-sync ]]; then
	for i in "${!Aaplayname[@]}"; do # get current aplay card number
		[[ ${Aaplayname[$i]} == $aplayname ]] && break
	done
	if [[ -n ${Amixermanual[i]} ]]; then
		hwmixer="${Amixermanual[i]}"
	elif [[ -n ${Ahwmixer[i]} ]]; then
		hwmixer="${Ahwmixer[i]}"
	fi
	alsa='alsa = {
	output_device = "hw:'${Acard[i]}'";'
	
	[[ -n $hwmixer ]] && alsa+='
	mixer_control_name = "'$hwmixer'";'
	
	alsa+='
}
	'
	sed -i '/^alsa =/,$ d' /etc/shairport-sync.conf
	echo "$alsa" >> /etc/shairport-sync.conf

	pushstream airplay '{"stop":"switchoutput"}'
	systemctl try-restart shairport-sync
fi

if [[ -e /usr/bin/spotifyd ]]; then
	if [[ -e $dirsystem/spotify-device ]]; then
		device=$( cat $dirsystem/spotifydset )
	else
		if [[ -e $usbdacfile ]]; then
			cardname=$( aplay -l | grep "^card.*$aplayname" | head -1 | cut -d' ' -f3 )
		else
			cardname=$( aplay -l | grep "^card ${Acard[i]}:" | head -1 | cut -d' ' -f3 )
		fi
		device=$( aplay -L | grep "^default.*$cardname" )
	fi
	sed -i "s/^\(device = \).*/\1$device/" /etc/spotifyd.conf
	systemctl try-restart spotifyd
fi
