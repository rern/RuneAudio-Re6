#!/bin/bash

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
chmod 755 /srv/http/* /srv/http/bash/* /srv/http/settings/*

# hostname
if [[ $( cat $dirsystem/hostname ) != RuneAudio ]]; then
	hostname=$( cat $dirsystem/hostname )
	hostnamelc=$( echo $hostname | tr '[:upper:]' '[:lower:]' )
	hostnamectl set-hostname $hostnamelc
	sed -i "s/\(.*\[\).*\(\] \[.*\)/\1$hostnamelc\2/" /etc/avahi/services/runeaudio.service
	sed -i "s/^\(ssid=\).*/\1$hostname/" /etc/hostapd/hostapd.conf &> /dev/null
	sed -i "s/\(netbios name = \"\).*/\1+ $hostnamelc +\"/" /etc/samba/smb.conf &> /dev/null
	sed -i "/ExecStart/ s/\\w*$/$hostname/" /etc/systemd/system/wsdd.service &> /dev/null
	sed -i "s/^\(name = \).*/\1$hostname" /etc/shairport-sync.conf &> /dev/null
	sed -i "s/^\(friendlyname = \).*/\1$hostname/" /etc/upmpdcli.conf &> /dev/null
fi
# chromium
if [[ -e /usr/bin/chromium ]]; then
	[[ -e $dirsystem/xinitrc ]] && cp -f $dirsystem/xinitrc /etc/X11/xinit/xinitrc
	[[ -e $dirsystem/rotatefile ]] && cp -f $dirsystem/rotatefile /etc/X11/xorg.conf.d/99-raspi-rotate.conf
	[[ -e $dirsystem/calibration ]] && cp -f $dirsystem/calibration /etc/X11/xorg.conf.d/99-calibration.conf
	if [[ ! -e $dirsystem/localbrowser ]]; then
		sed -i 's/\(console=\).*/\1tty1/' /boot/cmdline.txt
		enable=' getty@tty1'
		disable+=' localbrowser'
	fi
fi
# color
[[ -e $dirsystem/color ]] && color=1 && /srv/http/bash/cmd.sh color
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
if [[ -e /usr/bin/hostapd ]]; then
	if [[ -e $dirsystem/accesspoint-passphrase ]]; then
		passphrase=$( cat $dirsystem/accesspoint-passphrase )
		ip=$( cat $dirsystem/accesspoint-ip )
		iprange=$( cat $dirsystem/accesspoint-iprange )
		sed -i -e "/wpa\|rsn_pairwise/ s/^#*//
" -e "s/\(wpa_passphrase=\).*/\1$passphrase/
" /etc/hostapd/hostapd.conf
		sed -i -e "s/^\(dhcp-range=\).*/\1$iprange/
" -e "s/^\(dhcp-option-force=option:router,\).*/\1$ip/
" -e "s/^\(dhcp-option-force=option:dns-server,\).*/\1$ip/
" /etc/dnsmasq.conf
	fi
	[[ -e $dirsystem/accesspoint ]] && enable+=' hostapd'
fi
# login
[[ -e $dirsystem/login ]] && sed -i 's/\(bind_to_address\).*/\1           "127.0.0.1"/' /etc/mpd.conf
# mpd.conf
file=$dirsystem/mpd
if ls $file-* &> /dev/null; then
	[[ -e $file-autoupdate ]] &&    sed -i '1 i\auto_update             "yes"' /etc/mpd.conf
	[[ -e $file-buffer ]] &&        sed -i '1 i\audio_buffer_size       "'$( cat $dirsystem/mpd-buffer )'"' /etc/mpd.conf
	[[ -e $file-bufferoutput ]] &&  sed -i '/music_directory/ i\max_output_buffer_size  "'$( cat $dirsystem/mpd-bufferoutput )'"' /etc/mpd.conf
	[[ -e $file-ffmpeg ]] &&        sed -i '/ffmpeg/ {n;s/\(enabled\s*"\).*/\1yes"/}' /etc/mpd.conf
	[[ -e $file-normalization ]] && sed -i '/^user/ a\volume_normalization  "yes"' /etc/mpd.conf
	[[ -e $file-replaygain ]] &&    sed -i 's/\(replaygain\s*\"\).*/\1'$( cat $dirsystem/mpd-replaygain )'"/' /etc/mpd.conf
	[[ -e $file-soxr ]] &&          sed -i -e '/quality/,/}/ d' -e "/soxr/ r $file-soxrset" /etc/mpd.conf
fi
# mpdscribble
file=$dirsystem/mpdscribble
if [[ -e $file ]]; then
	sed -i -e 's/^\(username =\).*/\1 "'$( sed -n '1 p' $file )'"/
' -e 's/^\(password =\).*/\1 "'$( sed -n '2 p' $file )'"/
' /etc/mpdscribble.conf
	[[ -e $dirsystem/mpdscribble ]] && enable+=' mpdscribble'
fi
# ntp
[[ -e $dirsystem/ntp ]] && sed -i "s/#*NTP=.*/NTP=$( cat $dirsystem/ntp )/" /etc/systemd/timesyncd.conf
# samba
if [[ -e /ust/bin/samba ]]; then
	file=$dirsystem/samba
	[[ -e $file-readonlysd ]] && sed -i '/path = .*SD/,/\tread only = no/ {/read only/ d}' /etc/samba/smb.conf
	[[ -e $file-readonlyusb ]] && sed -i '/path = .*USB/,/\tread only = no/ {/read only/ d}' /etc/samba/smb.conf
	[[ -e $file ]] && enable+=' smb wsdd'
fi
# shairport-sync
[[ -e /usr/bin/shairport-sync && -e $dirsystem/airplay ]] && enable+=' shairport-sync'
# snapcast
if [[ -e /usr/bin/snapserver ]]; then
	[[ -e $dirsystem/snapcast ]] && enable+=' snapserver'
	[[ -e $dirsystem/snapcast-latency ]] && sed -i '/OPTS=/ s/".*"/"--latency='$( cat $dirsystem/snapcast-latency )'"/' /etc/default/snapclient
fi
# spotify
if [[ -e /usr/bin/spotifyd ]]; then
	[[ -e $dirsystem/spotify ]] && enable+=' spotifyd'
	[[ -e $dirsystem/spotify-device ]] && sed -i "s/^\(device = \).*/\1$( cat $dirsystem/spotify-device )/" /etc/spotifyd.conf
fi
# timezone
[[ -e $dirsystem/timezone ]] && timedatectl set-timezone $( cat $dirsystem/timezone )
# upmpdcli
if [[ -e /usr/bin/upmpdcli && -e $dirsystem/upnp ]]; then
	file=$dirsystem/upnp
	setUpnp() {
		user=( $( cat $dirsystem/upnp-$1user ) )
		pass=( $( cat $dirsystem/upnp-$1pass ) )
		quality=( $( cat $dirsystem/upnp-$1quality 2> /dev/null ) )
		[[ $1 == qobuz ]] && qlty=formatid || qlty=quallity
		sed -i -e "s/#*\($1user = \).*/\1$user/
" -e "s/#*\($1pass = \).*/\1$pass/
" -e "s/#*\($1$qlty = \).*/\1$quality/
" /etc/upmpdcli.conf
	}
	[[ -e $file-gmusicuser ]] && setUpnp gmusic
	[[ -e $file-qobuzuser ]] && setUpnp qobuz
	[[ -e $file-tidaluser ]] && setUpnp tidal
	[[ -e $file-spotifyuser ]] && setUpnp spotify
	[[ -e $file ]] && enable+=' upmpdcli'
fi

### config.txt
# remove before reinstate
sed -i -e '/dtparam=\|dtoverlay=/ d
' -e :a -e '/^\n*$/{$d;N;};/\n$/ba
' /boot/config.txt

# onboard bluetooth
if [[ -e $dirsystem/onboard-bluetooth ]]; then
	config+="\
dtparam=krnbt=on
"
	reboot+="\
Enable on-board Bluetooth
"
fi
# onboard wifi
if [[ ! -e $dirsystem/onboard-wlan ]]; then
	systemctl disable --now netctl-auto@wlan0
	rmmod brcmfmac
fi
# wifi regdom
if [[ -e $dirsystem/wlanregdom ]]; then
	regdom=$( cat $dirsystem/wlanregdom )
	sed -i 's/".*"/"'$regdom'"/' /etc/conf.d/wireless-regdom
	iw reg set $regdom
fi
# i2s audio
audioaplayname=$( cat $dirsystem/audio-aplayname 2> /dev/null )
audiooutput=$( cat $dirsystem/audio-output )
if grep -q "$audiooutput.*$audioaplayname" /srv/http/settings/system-i2s.json; then
	[[ -e $dirsystem/onboard-audio ]] && onoff=on || onoff=off
	config+="\
dtparam=audio=$onoff
"
	config+="\
dtparam=i2s=on
dtoverlay=$audioaplayname
"
	reboot+="\
Enable I2S Module
"
elif [[ ! -e $dirsystem/onboard-audio ]]; then
	config+="\
dtparam=audio=off
"
	reboot+="\
Disable on-board audio
"
else
	config+="\
dtparam=audio=on
"
fi

if [[ -e $dirsystem/lcd ]]; then
	sed -i '1 s/$/ console=ttyAMA0,115200 fbcon=map:10 fbcon=font:ProFont6x11/' /boot/cmdline.txt
	cp {$dirsystem,/etc/X11/xorg.conf.d}/99-calibration.conf
	config+="\
hdmi_force_hotplug=1
dtparam=i2c_arm=on
dtparam=spi=on
dtoverlay=tft35a
"
	echo -n "\
i2c-bcm2708
i2c-dev
" >> /etc/modules-load.d/raspberrypi.conf
	sed -i 's/fb0/fb1/' /usr/share/X11/xorg.conf.d/99-fbturbo.conf
fi

[[ -n $config ]] && echo -n "$config" >> /boot/config.txt

notify() {
	curl -s -X POST http://127.0.0.1/pub?id=restore -d '{"restore":"'$1'"}' &> /dev/null
}

if [[ -z $reboot ]]; then
	[[ -n $disable ]] && systemctl -q disable --now $disable
	for item in $enable; do
		notify $item
		systemctl -q enable --now $item
	done
	sleep 3
	[[ -e $dirsystem/updating ]] && /srv/http/bash/cmd.sh mpcupdate
else 
	echo -n "$reboot" > /srv/http/data/shm/reboot
	[[ -n $disable ]] && systemctl -q disable $disable
	for item in $enable; do
		systemctl -q enable $item
	done
fi

systemctl start mpd

notify done
