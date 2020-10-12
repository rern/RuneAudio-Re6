#!/bin/bash

# get hardware devices data with 'aplay' and amixer
# - aplay - get card index, sub-device index and aplayname
# - if on-board or wm5102, get name and routeid from each var list
# - mixer device
#    - from file if manually set
#    - from 'amixer'
#        - if more than 1, filter with 'Digital\|Master' | get 1st one
# - mixer_type
#    - from file if manually set
#    - set as hardware if mixer device available
#    - if nothing, set as software

aplay=$( aplay -l | grep '^card' )
cardL=$( echo "$aplay" | wc -l )

wm5102=( 'WM5102 - Line' 'WM5102 - S/PDIF' 'WM5102 - Headphone' 'WM5102 - Speaker' )
audioaplayname=$( cat /srv/http/data/system/audio-aplayname )

readarray -t lines <<<"$aplay"
for line in "${lines[@]}"; do
	hw=$( echo $line | sed 's/card \(.*\):.*device \(.*\):.*/hw:\1,\2/' )
	card=${hw:3:1}
	device=${hw: -1}
	aplayname=$( echo $line \
		| awk -F'[][]' '{print $2}' )
	# aplay -l: snd_rpi_xxx_yyy > xxx-yyy
	[[ ${aplayname:0:7} == snd_rpi ]] && aplayname=$( echo $aplayname | sed 's/^snd_rpi_//; s/_/-/g' )
	case "$aplayname" in
		'bcm2835 HDMI 1' )     name='On-board - HDMI';;
		'bcm2835 Headphones' ) name='On-board - Headphone';;
		'rpi-cirrus-wm5102' )  name=${wm5102[$device]};;
		* )                    (( $device == 0 )) && name=$aplayname || name="$aplayname $device";;
	esac
	# user selected
	hwmixerfile=/srv/http/data/system/mpd-hwmixer-$card
	if [[ -e $hwmixerfile ]]; then
		hwmixer=$( cat $hwmixerfile )
		mixermanual=$hwmixer
	else
		mixermanual=
		amixer=$( amixer -c $card scontents \
			| grep -A2 'Simple mixer control' \
			| grep -v 'Capabilities' \
			| tr -d '\n' \
			| sed 's/--/\n/g' \
			| grep 'Playback channels' \
			| sed "s/.*'\(.*\)',\(.\) .*/\1 \2/; s/ 0$//" \
			| awk '!a[$0]++' )
		mixercount=$( echo "$amixer" | wc -l )
		if (( $mixercount == 0 )); then
			hwmixer=
		elif (( $mixercount == 1 )); then
			hwmixer=$amixer
		else
			hwmixer=$( echo "$amixer" | grep 'Digital\|Master' | head -1 )
			[[ -z $hwmixer ]] && hwmixer=$( echo "$amixer" | head -1 )
		fi
	fi
	
	mixertypefile="/srv/http/data/system/mpd-mixertype-$name"
	if [[ -e $mixertypefile ]]; then
		mixertype=$( cat "$mixertypefile" )
	elif [[ -n $hwmixer ]]; then
		mixertype=hardware
	else
		mixertype=software
	fi
	
	[[ -e "/srv/http/data/system/mpd-dop-$name" ]] && dop=1 || dop=0
	
	Aaplayname+=( "$aplayname" )
	Acard+=( "$card" )
	Adevice+=( "$device" )
	Adop+=( "$dop" )
	Ahw+=( "$hw" )
	Ahwmixer+=( "$hwmixer" )
	Amixercount+=( "$mixercount" )
	Amixermanual+=( "$mixermanual" )
	Amixertype+=( "$mixertype" )
	Aname+=( "$name" )
done
