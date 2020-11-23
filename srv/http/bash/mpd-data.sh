#!/bin/bash

dirsystem=/srv/http/data/system

. /srv/http/bash/mpd-devices.sh

for (( i=0; i < cardL; i++ )); do
	# json inside array needs "escaped double quotes"
	devices+='{
		  "aplayname"    : "'${Aaplayname[i]}'"
		, "card"         : '${Acard[i]}'
		, "device"       : '${Adevice[i]}'
		, "dop"          : '${Adop[i]}'
		, "format"       : "'${Aformat[i]}'"
		, "mixercount"   : '${Amixercount[i]}'
		, "mixermanual"  : "'${Amixermanual[i]}'"
		, "mixertype"    : "'${Amixertype[i]}'"
		, "name"         : "'${Aname[i]}'"
		, "hw"           : "'${Ahw[i]}'"
		, "hwmixer"      : "'${Ahwmixer[i]}'"
	},'
done
devices=${devices:0:-1}

data='
	  "devices"         : ['$devices']
	, "audiooutput"     : "'$( cat $dirsystem/audio-output )'"
	, "audioaplayname"  : "'$( cat $dirsystem/audio-aplayname )'"
	, "autoupdate"      : '$( grep -q '^auto_update.*yes' /etc/mpd.conf && echo true || echo false )'
	, "buffer"          : '$( grep -q '^audio_buffer_size' /etc/mpd.conf && echo true || echo false )'
	, "bufferset"       : '$( [[ -e $dirsystem/mpd-bufferset ]] && echo true || echo false )'
	, "bufferval"       : '$( cat $dirsystem/mpd-bufferset 2> /dev/null || echo false )'
	, "bufferoutput"    : '$( grep -q '^max_output_buffer_size' /etc/mpd.conf && echo true || echo false )'
	, "bufferoutputset" : '$( [[ -e $dirsystem/mpd-bufferoutputset ]] && echo true || echo false )'
	, "bufferoutputval" : '$( cat $dirsystem/mpd-bufferoutputset 2> /dev/null || echo false )'
	, "crossfade"       : '$( [[ $( mpc crossfade | cut -d' ' -f2 ) != 0 ]] && echo true || echo false )'
	, "crossfadeset"    : '$( [[ -e $dirsystem/mpd-crossfadeset ]] && echo true || echo false )'
	, "crossfadeval"    : '$( cat $dirsystem/mpd-crossfadeset 2> /dev/null || echo false )'
	, "custom"          : '$( [[ -e $dirsystem/mpd-custom ]] && echo true || echo false )'
	, "customset"       : '$( [[ -e $dirsystem/mpd-customset ]] && echo true || echo false )'
	, "ffmpeg"          : '$( grep -A1 'plugin.*ffmpeg' /etc/mpd.conf | grep -q yes && echo true || echo false )'
	, "normalization"   : '$( grep -q 'volume_normalization.*yes' /etc/mpd.conf && echo true || echo false )'
	, "reboot"          : "'$( cat /srv/http/data/shm/reboot 2> /dev/null )'"
	, "replaygain"      : '$( grep -q '^replaygain.*off' /etc/mpd.conf && echo false || echo true )'
	, "replaygainset"   : '$( [[ -e $dirsystem/mpd-replaygainset ]] && echo true || echo false )'
	, "replaygainval"   : "'$( cat $dirsystem/mpd-replaygainset 2> /dev/null )'"
	, "usbdac"          : "'$( cat /srv/http/data/shm/usbdac 2> /dev/null )'"
	, "soxr"            : '$( grep -q "quality.*custom" /etc/mpd.conf && echo true || echo false )'
	, "soxrset"         : '$( [[ -e $dirsystem/mpd-soxrset ]] && echo true || echo false )'
	, "soxrval"         : "'$( grep -v 'quality\|}' $dirsystem/mpd-soxrset 2> /dev/null | cut -d'"' -f2 )'"
'
echo {$data}
