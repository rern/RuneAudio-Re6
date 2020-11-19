#!/bin/bash

dirsystem=/srv/http/data/system
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
		, "format"      : "'${Aformat[i]}'"
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
	, "audiooutput"    : "'$( cat $dirsystem/audio-output )'"
	, "audioaplayname" : "'$( cat $dirsystem/audio-aplayname )'"
	, "autoplay"       : '$( [[ -e $dirsystem/autoplay ]] && echo true || echo false )'
	, "autoupdate"     : '$( grep -q "auto_update.*yes" /etc/mpd.conf && echo true || echo false )'
	, "buffer"         : "'$( grep audio_buffer_size /etc/mpd.conf | cut -d'"' -f2 )'"
	, "bufferoutput"   : "'$( grep max_output_buffer_size /etc/mpd.conf | cut -d'"' -f2 )'"
	, "crossfade"      : '$( ( mpc crossfade 2> /dev/null || grep crossfade /srv/http/data/mpd/mpdstate ) | cut -d' ' -f2 )'
	, "crossfadeset"   : '$( cat $dirsystem/mpd-crossfadeset 2> /dev/null || echo false )'
	, "custom"         : '$( [[ -e $dirsystem/mpd-custom ]] && echo true || echo false )'
	, "customset"      : '$( cat $dirsystem/mpd-crossfadeset 2> /dev/null || echo false )'
	, "customglobal"   : "'$( sed 's/^\t\| #custom$//g' $file-global 2> /dev/null )'"
	, "customoutput"   : "'$( sed 's/^\t\| #custom$//g' $file-output 2> /dev/null )'"
	, "ffmpeg"         : '$( grep -A1 ffmpeg /etc/mpd.conf | grep -q yes && echo true || echo false )'
	, "manualconf"     : '$( [[ -e $dirsystem/mpd-manualconf ]] && echo true || echo false )'
	, "mixertype"      : "'$( grep mixer_type /etc/mpd.conf | cut -d'"' -f2 )'"
	, "normalization"  : '$( grep -q 'volume_normalization.*yes' /etc/mpd.conf && echo true || echo false )'
	, "reboot"         : "'$( cat /srv/http/data/shm/reboot 2> /dev/null )'"
	, "replaygain"     : "'$( grep replaygain /etc/mpd.conf | cut -d'"' -f2 )'"
	, "usbdac"         : "'$( cat /srv/http/data/shm/usbdac 2> /dev/null )'"
	, "soxr"           : '$( grep -q "quality.*custom" /etc/mpd.conf && echo true || echo false )'
	, "soxrset"        : "'$( grep -v 'quality\|}' $dirsystem/mpd-soxrset | cut -d'"' -f2 )'"
'
echo {$data}
