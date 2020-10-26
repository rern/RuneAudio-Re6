#!/bin/bash

amixer=$( amixer scontrols | cut -d"'" -f2 )
readarray -t lines <<<"$amixer"
for line in "${lines[@]}"; do
	mixerdevices+='"'$line'",'
done
mixerdevices=${mixerdevices:0:-1}

. /srv/http/bash/mpd-devices.sh

for (( i=0; i < cardL; i++ )); do
	# json inside array needs "escaped double quotes"
	devices+='{
		  "aplayname"   : "'${Aaplayname[i]}'"
		, "card"        : '${Acard[i]}'
		, "device"      : '${Adevice[i]}'
		, "dop"         : '${Adop[i]}'
		, "mixercount"  : '${Amixercount[i]}'
		, "mixermanual" : "'${Amixermanual[i]}'"
		, "mixertype"   : "'${Amixertype[i]}'"
		, "name"        : "'${Aname[i]}'"
		, "hw"          : "'${Ahw[i]}'"
		, "hwmixer"     : "'${Ahwmixer[i]}'"
	},'
done
devices=${devices:0:-1}

data='
	  "devices"        : ['$devices']
	, "mixerdevices"   : ['$mixerdevices']
	, "audiooutput"    : "'$( cat /srv/http/data/system/audio-output )'"
	, "audioaplayname" : "'$( cat /srv/http/data/system/audio-aplayname )'"
	, "autoplay"       : '$( [[ -e /srv/http/data/system/autoplay ]] && echo true || echo false )'
	, "autoupdate"     : '$( grep -q "auto_update.*yes" /etc/mpd.conf && echo true || echo false )'
	, "buffer"         : "'$( grep audio_buffer_size /etc/mpd.conf | cut -d'"' -f2 )'"
	, "bufferoutput"   : "'$( grep max_output_buffer_size /etc/mpd.conf | cut -d'"' -f2 )'"
	, "crossfade"      : '$( ( mpc crossfade 2> /dev/null || grep crossfade /srv/http/data/mpd/mpdstate ) | cut -d' ' -f2 )'
	, "ffmpeg"         : '$( grep -A1 ffmpeg /etc/mpd.conf | grep -q yes && echo true || echo false )'
	, "mixertype"      : "'$( grep mixer_type /etc/mpd.conf | cut -d'"' -f2 )'"
	, "normalization"  : '$( grep -q 'volume_normalization.*yes' /etc/mpd.conf && echo true || echo false )'
	, "reboot"          : "'$( cat /srv/http/data/shm/reboot 2> /dev/null )'"
	, "replaygain"     : "'$( grep replaygain /etc/mpd.conf | cut -d'"' -f2 )'"
	, "usbdac"         : "'$( cat /srv/http/data/shm/usbdac 2> /dev/null )'"
'
echo {$data}
