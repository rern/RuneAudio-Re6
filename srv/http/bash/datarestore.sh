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

# features #################################################################
# accesspoint
[[ -e $dirsystem/hostapdset ]] && $dirbash/features.sh hostapdset$'\n'"$( cat $dirsystem/hostapdset )"
[[ -e $dirsystem/hostapd ]] && $dirbash/features.sh hostapd$'\n'true

# airplay
[[ -e $dirsystem/shairport-sync ]] && $dirbash/features.sh shairport-sync$'\n'true

# localbrowser
[[ ! -e $dirsystem/localbrowser ]] && $dirbash/features.sh localbrowser$'\n'false
[[ -e $dirsystem/localbrowserset ]] && $dirbash/features.sh localbrowserset$'\n'"$( cat $dirsystem/localbrowserset )"

# login
[[ -e $dirsystem/loginset ]] && $dirbash/features.sh loginset$'\n'"$( cat $dirsystem/loginset )"
[[ -e $dirsystem/login ]] && $dirbash/features.sh login$'\n'true

# mpdscribble
[[ -e $dirsystem/mpdscribbleset ]] && $dirbash/features.sh mpdscribbleset$'\n'"$( cat $dirsystem/mpdscribbleset )"
[[ -e $dirsystem/mpdscribble ]] && $dirbash/features.sh mpdscribble$'\n'true

# samba
[[ -e $dirsystem/smbset ]] && $dirbash/features.sh smbset$'\n'"$( cat $dirsystem/smbset )"
[[ -e $dirsystem/smb ]] && $dirbash/features.sh smb$'\n'true

# snapcast
[[ -e $dirsystem/snapserver ]] && $dirbash/features.sh snapserver$'\n'true

# snapclient
[[ -e $dirsystem/snapclientset ]] && $dirbash/features.sh snapclientset$'\n'"$( cat $dirsystem/snapclientset )"
[[ -e $dirsystem/snapclient ]] && $dirbash/features.sh snapclient$'\n'true

# spotify
[[ -e $dirsystem/spotifydset ]] && $dirbash/features.sh spotifydset$'\n'"$( cat $dirsystem/spotifydset )"
[[ -e $dirsystem/spotifyd ]] && $dirbash/features.sh spotifyd$'\n'true

# upnp
[[ -e $dirsystem/upmpdcli ]] && $dirbash/features.sh upmpdcli$'\n'true

# system #################################################################
# bluetooth
[[ -e $dirsystem/onboard-bluetooth ]] && $dirbash/system.sh bluetooth$'\n'true

# hostname
[[ $( cat $dirsystem/hostname ) != RuneAudio ]] && $dirbash/system.sh hostname$'\n'$( cat $dirsystem/hostname )

# i2smodule
aplayname=$( cat $dirsystem/audio-aplayname 2> /dev/null )
output=$( cat $dirsystem/audio-output )
grep -q "$output.*$aplayname" /srv/http/settings/system-i2s.json && $dirbash/system.sh i2smodule$'\n'"$aplayname"$'\n'"$output"

# lcd
[[ -e $dirsystem/calibration ]] && cp -f $dirsystem/calibration /etc/X11/xorg.conf.d/99-calibration.conf
[[ -e $dirsystem/lcd ]] && $dirbash/system.sh lcd$'\n'true

# lcdchar
[[ -e $dirsystem/lcdcharset ]] && $dirbash/system.sh lcdcharset$'\n'"$( cat $dirsystem/lcdcharset )"
[[ -e $dirsystem/lcdchar ]] && $dirbash/system.sh lcdchar$'\n'true

# onboardaudio
[[ ! -e $dirsystem/onboard-audio ]] && $dirbash/system.sh onboardaudio$'\n'false

# regional
[[ -e $dirsystem/regional ]] && $dirbash/features.sh regional$'\n'"$( cat $dirsystem/regional )"

# soundprofile
[[ -e $dirsystem/soundprofileset ]] && $dirbash/system.sh soundprofileset$'\n'"$( cat $dirsystem/soundprofileset )"
[[ -e $dirsystem/soundprofile ]] && $dirbash/system.sh soundprofile$'\n'true

# timezone
[[ -e $dirsystem/timezone ]] && $dirbash/system.sh timezone$'\n'"$( cat $dirsystem/timezone )"

# wlan
[[ ! -e $dirsystem/onboard-wlan ]] && $dirbash/system.sh wlan$'\n'false

# mpd #################################################################
# mpd.conf
file=$dirsystem/mpd
if ls $file-* &> /dev/null; then
	touch /srv/http/data/shm/datarestore
	[[ -e $file-autoupdate ]] &&    $dirbash/mpd.sh autoupdate$'\n'true
	[[ -e $file-buffer ]] &&        $dirbash/mpd.sh bufferset$'\n'$( cat $file-buffer )
	[[ -e $file-bufferoutput ]] &&  $dirbash/mpd.sh bufferoutputset$'\n'$( cat $file-bufferoutput )
	[[ -e $file-crossfade ]] &&     $dirbash/mpd.sh crossfadeset$'\n'$( cat $file-crossfade )
	[[ -e $file-custom ]] &&        $dirbash/mpd.sh customset$'\n'$( cat $file-custom-global )
	[[ -e $file-ffmpeg ]] &&        $dirbash/mpd.sh ffmpeg$'\n'true
	[[ -e $file-normalization ]] && $dirbash/mpd.sh normalization$'\n'true
	[[ -e $file-replaygain ]] &&    $dirbash/mpd.sh replaygainset$'\n'$( cat $file-replaygain )
	[[ -e $file-soxr ]] &&          $dirbash/mpd.sh soxrset$'\n'$( cat $file-soxrset )
	rm /srv/http/data/shm/datarestore
	/srv/http/bash/mpd-conf.sh
fi

# networks #################################################################
netctl=$( ls -1 $dirsystem/netctl-* 2> /dev/null | head -1 )
[[ -n $netctl ]] && cp "$netctl" /boot/wifi

# sources #################################################################
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

curl -s -X POST http://127.0.0.1/pub?id=refresh -d '{ "page": "system" }'
