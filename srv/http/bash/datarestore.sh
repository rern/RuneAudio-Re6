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
# airplay
[[ -e /usr/bin/shairport-sync && -e $dirsystem/airplay ]] && $dirbash/features.sh airplay$'\n'true
# spotify
if [[ -e $dirsystem/spotify ]]; then
	if [[ -e $dirsystem/spotifyset ]]; then
		$dirbash/features.sh spotifyset$'\n'"$( cat $dirsystem/spotifyset )"
	else
		$dirbash/features.sh spotify$'\n'true
	fi
# upmpdcli
[[ -e /usr/bin/upmpdcli && -e $dirsystem/upnp ]] && $dirbash/features.sh upnp$'\n'true
# snapcast
[[ -e $dirsystem/snapcast ]] && $dirbash/features.sh snapcast$'\n'true
# chromium
if [[ ! -e $dirsystem/localbrowser ]]; then
	if [[ -e $dirsystem/localbrowserset ]]; then
		$dirbash/features.sh localbrowserset$'\n'"$( cat $dirsystem/localbrowserset )"
	else
		$dirbash/features.sh localbrowser$'\n'false
	fi
fi
[[ -e $dirsystem/calibration ]] && cp -f $dirsystem/calibration /etc/X11/xorg.conf.d/99-calibration.conf
# samba
if [[ -e $dirsystem/samba ]]; then
	if [[ -e $dirsystem/sambaset ]]; then
		$dirbash/features.sh sambaset$'\n'"$( cat $dirsystem/sambaset )"
	else
		$dirbash/features.sh samba$'\n'true
	fi
fi
# mpdscribble
[[ -e $dirsystem/mpdscribble ]] && $dirbash/features.sh mpdscribbleset$'\n'"$( cat $dirsystem/mpdscribbleset )"
# login
[[ -e $dirsystem/login ]] && $dirbash/features.sh login$'\n'true
# accesspoint
if [[ -e $dirsystem/accesspoint ]]; then
	if [[ -e $dirsystem/accesspointset ]]; then
		$dirbash/features.sh accesspointset$'\n'"$( cat $dirsystem/accesspointset )"
	else
		$dirbash/features.sh accesspoint$'\n'true
	fi

# system #################################################################
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
# 480x320 lcd
[[ -e $dirsystem/lcd ]] && $dirbash/system.sh lcd lcd$'\n'true
# character lcd
if [[ -e $dirsystem/lcdchar ]]; then
	if [[ -e $dirsystem/lcdcharset ]]; then
		$dirbash/system.sh lcdcharset$'\n'"$( cat $dirsystem/lcdcharset )"
	else
		$dirbash/system.sh lcdchar$'\n'true
	fi
# hostname
[[ $( cat $dirsystem/hostname ) != RuneAudio ]] && $dirbash/system.sh hostname$'\n'$( cat $dirsystem/hostname )
# timezone
[[ -e $dirsystem/timezone ]] && timedatectl set-timezone $( cat $dirsystem/timezone )
# regional
[[ -e $dirsystem/regional ]] && $dirbash/features.sh regional$'\n'"$( cat $dirsystem/regional )"
# soundprofile
[[ -e $dirsystem/soundprofile ]] && $dirbash/system.sh soundprofileset$'\n'"$( cat $dirsystem/soundprofileset )"

# mpd #################################################################
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
