#!/bin/bash

dirbash=/srv/http/bash
dirdata=/srv/http/data
diraddons=$dirdata/addons
dirsystem=$dirdata/system
dirtmp=$dirdata/shm
dirdatatmp=$dirdata/tmp

# clear default enabled features and updating flags
rm -f $dirsystem/{localbrowser,onboard-audio,onboard-wlan,updating,listing,wav}

mv $diraddons $dirtmp

systemctl stop mpd

backupfile=$dirdatatmp/backup.gz
bsdtar -xpf $backupfile -C /srv/http
rm -f $backupfile

mv $dirtmp/addons $dirdata

chown -R http:http /srv/http
chown mpd:audio $dirdata/mpd/mpd* &> /dev/null
chmod 755 /srv/http/* $dirbash/* /srv/http/settings/*

# hostname
if [[ $( cat $dirsystem/hostname ) != RuneAudio ]]; then
	hostname=$( cat $dirsystem/hostname )
	$dirbash/system.sh hostname$'\n'$hostname
fi
# chromium
[[ ! -e $dirsystem/localbrowser ]] && $dirbash/features.sh localbrowser$'\n'false
[[ -e $dirsystem/localbrowserset ]] && $dirbash/features.sh localbrowserset$'\n'"$( cat $dirsystem/localbrowserset )"
[[ -e $dirsystem/calibration ]] && cp -f $dirsystem/calibration /etc/X11/xorg.conf.d/99-calibration.conf
# color
[[ -e $dirsystem/color ]] && color=1 && $dirbash/cmd.sh color
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
# hostapd
[[ -e $dirsystem/accesspoint ]] && $dirbash/features.sh accesspointset$'\n'"$( cat $dirsystem/accesspoint )"
# login
[[ -e $dirsystem/login ]] && $dirbash/features.sh login$'\n'true
# mpd.conf
file=$dirsystem/mpd
if ls $file-* &> /dev/null; then
	touch /srv/http/data/shm/datarestore
	[[ -e $file-autoupdate ]] &&    $dirbash/mpd.sh autoupdate$'\n'true
	[[ -e $file-buffer ]] &&        $dirbash/mpd.sh buffer$'\n'$( cat $file-buffer )
	[[ -e $file-bufferoutput ]] &&  $dirbash/mpd.sh bufferoutput$'\n'$( cat $file-bufferoutput )
	[[ -e $file-ffmpeg ]] &&        $dirbash/mpd.sh ffmpeg$'\n'true
	[[ -e $file-normalization ]] && $dirbash/mpd.sh normalization$'\n'true
	[[ -e $file-replaygain ]] &&    $dirbash/mpd.sh replaygain$'\n'$( cat $file-replaygain )
	[[ -e $file-custom-global ]] && $dirbash/mpd.sh customset$'\n'$( cat $file-custom-global )
	[[ -e $file-soxr ]] &&          $dirbash/mpd.sh soxrset$'\n'$( cat $file-soxrset )
	rm /srv/http/data/shm/datarestore
	/srv/http/bash/mpd-conf.sh
fi
# mpdscribble
[[ -e $dirsystem/mpdscribbleset ]] && $dirbash/features.sh mpdscribbleset$'\n'"$( cat $dirsystem/mpdscribbleset )"
# regional
[[ -e $dirsystem/regional ]] && $dirbash/features.sh regional$'\n'"$( cat $dirsystem/regional )"
# samba
[[ -e $dirsystem/sambaset ]] && $dirbash/features.sh samba$'\n'"$( cat $dirsystem/sambaset )"
[[ -e $dirsystem/samba ]] && $dirbash/features.sh sambaset$'\n'true
# shairport-sync
[[ -e /usr/bin/shairport-sync && -e $dirsystem/airplay ]] && $dirbash/features.sh airplay$'\n'true
# snapcast
[[ -e $dirsystem/snapcast ]] && $dirbash/features.sh snapcast$'\n'true
[[ -e $dirsystem/snapclientset ]] && $dirbash/features.sh snapclientset$'\n'"$( cat $dirsystem/snapclientset )"
# spotify
[[ -e $dirsystem/spotify ]] && $dirbash/features.sh spotify$'\n'true
[[ -e $dirsystem/spotifyset ]] && $dirbash/features.sh spotifyset$'\n'"$( cat $dirsystem/spotify-device )"
# timezone
[[ -e $dirsystem/timezone ]] && timedatectl set-timezone $( cat $dirsystem/timezone )
# upmpdcli
[[ -e /usr/bin/upmpdcli && -e $dirsystem/upnp ]] && $dirbash/features.sh upnp$'\n'true

### config.txt
# onboard bluetooth
[[ -e $dirsystem/onboard-bluetooth ]] && $dirbash/system.sh bluetooth$'\n'true
# onboard wifi
[[ ! -e $dirsystem/onboard-wlan ]] && $dirbash/system.sh wlan$'\n'false
# i2s audio
aplayname=$( cat $dirsystem/audio-aplayname 2> /dev/null )
output=$( cat $dirsystem/audio-output )
grep -q "$output.*$aplayname" /srv/http/settings/system-i2s.json && $dirbash/system.sh i2smodule$'\n'"$aplayname"$'\n'"$output"
# onboard audio
[[ ! -e $dirsystem/onboard-audio ]] && $dirbash/system.sh onboardaudio$'\n'false

[[ -e $dirsystem/lcdchar ]] && $dirbash/system.sh lcdcharset$'\n'"$( cat $dirsystem/lcdchar )"

[[ -e $dirsystem/lcd ]] && $dirbash/system.sh lcd lcd$'\n'true
