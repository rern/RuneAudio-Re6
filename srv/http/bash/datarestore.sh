#!/bin/bash

dirbash=/srv/http/bash
dirdata=/srv/http/data
dirsystem=$dirdata/system

# clear default enabled features and updating flags
rm -f $dirsystem/{localbrowser,onboard-audio,onboard-wlan,updating,listing,wav}

mv $dirdata/addons $dirdata/shm

systemctl stop mpd

backupfile=$dirdata/tmp/backup.gz
bsdtar -xpf $backupfile -C /srv/http
rm -f $backupfile

mv $dirdata/shm/addons $dirdata

chown -R http:http /srv/http
chown mpd:audio $dirdata/mpd/mpd* &> /dev/null
chmod 755 /srv/http/* $dirbash/* /srv/http/settings/*

# datafileset:
# hostapd, localbrowser, mpdscribble, smb, snapclient
# bluetooth, lcdchar, soundprofile
# buffer, bufferoutput, crossfade, custom, replaygain, soxr

serviceEnable() {
	for service in $2; do
		[[ $1 != mpd ]] && servicefile=$service || servicefile=mpd-$service
		[[ -e $dirsystem/$servicefile ]] && $dirbash/$1.sh ${service/-}'\n'true
	done
}
serviceSet() {
	for service in $2; do
		[[ $1 != mpd ]] && servicefile=$service || servicefile=mpd-$service
		[[ -e $dirsystem/$servicefile ]] && $dirbash/$1.sh ${service}set$'\n'"$( cat $dirsystem/${servicefile}set )"
	done
}

[[ -e $dirsystem/spotifydset ]] && $dirbash/features.sh spotifydset$'\n'"$( cat $dirsystem/spotifydset )"
[[ -e $dirsystem/calibration ]] && cp -f $dirsystem/calibration /etc/X11/xorg.conf.d/99-calibration.conf

serviceSet features 'hostapd localbrowser mpdscribble smb snapclient'
serviceEnable features 'shairport-sync snapserver spotifyd upmpdcli'
serviceSet system 'bluetooth lcdchar soundprofile'
serviceEnable system 'lcd onboard-audio onboard-wlan'

touch /srv/http/data/shm/datarestore
serviceSet mpd 'buffer bufferoutput crossfade custom replaygain soxr'
serviceEnable mpd 'autoupdate ffmpeg normalization'
rm /srv/http/data/shm/datarestore
/srv/http/bash/mpd-conf.sh

# audio i2s
aplayname=$( cat $dirsystem/audio-aplayname 2> /dev/null )
output=$( cat $dirsystem/audio-output )
grep -q "$output.*$aplayname" /srv/http/settings/system-i2s.json && $dirbash/system.sh i2smodule$'\n'"$aplayname"$'\n'"$output"
# hostname
[[ $( cat $dirsystem/hostname ) != RuneAudio ]] && $dirbash/system.sh hostname$'\n'$( cat $dirsystem/hostname )
# timezone
[[ -e $dirsystem/timezone ]] && $dirbash/system.sh timezone$'\n'"$( cat $dirsystem/timezone )"
# regional
[[ -e $dirsystem/regional ]] && $dirbash/features.sh regional$'\n'"$( cat $dirsystem/regional )"
# netctl
netctl=$( ls -1 $dirsystem/netctl-* 2> /dev/null | head -1 )
[[ -n $netctl ]] && cp "$netctl" /boot/wifi
# fstab
if ls $dirsystem/fstab-* &> /dev/null; then
	sed -i '\|/mnt/MPD/NAS| d' /etc/fstab
	rmdir /mnt/MPD/NAS/* &> /dev/null
	files=( $dirsystem/fstab-* )
	for file in "${files[@]}"; do
		cat $file >> /etc/fstab
		mkdir -p "/mnt/MPD/NAS/${file/*fstab-}"
	done
	mount -a
fi
# color
[[ -e $dirsystem/color ]] && color=1 && $dirbash/cmd.sh color

curl -s -X POST http://127.0.0.1/pub?id=refresh -d '{ "page": "all" }'
