#!/bin/bash

alias=rre6

. /srv/http/bash/addons.sh

installstart "$1"

getinstallzip

dirsystem=/srv/http/data/system

sed -i '/IgnorePkg.*linux-raspberrypi/ d' /etc/pacman.conf

if [[ $( cat /srv/http/data/addons/rre6 ) < 20201123 ]]; then
	rm -f $dirsystem/{lcdchar*,soundprofile*,snapclient*,localbrowser*,smb*,mpdscribble*,login*,hostapd*,mpd-*}
	grep -q dtoverlay=tft35a /boot/config/txt && touch $dirsystem/lcd
	grep -q 'dtparam=i2c_arm=on' /boot/config/txt && ! grep -q 'dtoverlay=tft35a' /boot/config/txt && touch $dirsystem/lcdchar
	if [[ -e $dirsystem/lcdchar ]] ; then
		grep '^cols\|^charmap\|^address\|^chip' /srv/http/bash/lcdchar.py | cut -d' ' -f3 | tr -d "'" > $dirsystem/lcdcharset
	else
		echo '20 A00 0x27 PCF8574' > $dirsystem/lcdcharset
	fi
	/srv/http/bash/system.sh soundprofileset$'\n18000000 60 1500 1000'
	service=( snapclient localbrowser smb mpdscribble hostapd )
	for service in snapclient localbrowser smb mpdscribble hostapd; do
		systemctl -q is-active $service && touch $dirsystem/$service
	done
fi

file=/etc/systemd/system/dnsmasq.service.d/override.conf
if [[ ! -e $file ]]; then
	mkdir -p /etc/systemd/system/{dnsmasq,hostapd}.service.d
	echo "[Unit]
Requires=hostapd.service
After=hostapd.service" > $file
	echo "[Unit]
BindsTo=dnsmasq.service" > /etc/systemd/system/hostapd.service.d/override.conf
	systemctl try-restart hostapd
fi

file=/etc/systemd/system/smb.service.d/override.conf
if [[ ! -e $file ]]; then
	mkdir -p /etc/systemd/system/smb.service.d
	echo "[Unit]
BindsTo=wsdd.service" > $file
	sed -i -e '/After=/ s/$/ smb.service/
' -e '/Wants=/ a\Requires=smb.service
' /etc/systemd/system/wsdd.service
	systemctl try-restart smb
fi

# system
mv $dirsystem/{gpio,relays} &> /dev/null
files=$dirsystem/{ntp,wlanregdom}
if [[ -e $dirsystem/ntp ]]; then
	cat $files > $dirsystem/regional
	rm $files
fi

# features
mv $dirsystem/{airplay,shairport-sync} &> /dev/null
files=$dirsystem/{snapcast-latency,snapserverpw}
if [[ -e $dirsystem/snapcast-latency ]]; then
	cat $files > $dirsystem/snapclientset
	rm $files
fi
mv $dirsystem/{snapcast,snapserver} &> /dev/null
mv $dirsystem/spotify{,d} &> /dev/null
mv $dirsystem/spotify{-device,dset} &> /dev/null
mv $dirsystem/{upnp,upmpdcli} &> /dev/null
if [[ -e /usr/bin/chromium && -e $dirsystem/localbrowser && ! -e $dirsystem/localbrowserset ]]; then
	file=/etc/X11/xorg.conf.d/99-raspi-rotate.conf
	[[ -e $file ]] && rotate=$( grep rotate $file 2> /dev/null | cut -d'"' -f4 ) || rotate=NORMAL
	xinitrc=/etc/X11/xinit/xinitrc
	screenoff=$( grep 'xset dpms .*' $xinitrc | cut -d' ' -f5 )
	cursor=$( grep -q 'cursor yes' $xinitrc && echo true || echo false )
	zoom=$( grep factor $xinitrc | cut -d'=' -f3 )
	printf '%s\n' $rotate $screenoff $cursor $zoom > $dirsystem/localbrowserset
fi
files=$dirsystem/{samba-readonlysd,samba-readonlyusb}
if [[ -e $dirsystem/samba-readonlysd ]]; then
	cat $files > $dirsystem/smbset
	rm $files
fi
mv $dirsystem/mpdscribble{-login,set} &> /dev/null
mv $dirsystem/{accesspoint,hostapd} &> /dev/null
files=$dirsystem/{accesspoint-ip,accesspoint-iprange,accesspoint-passphrase}
if [[ -e $dirsystem/accesspoint-ip ]]; then
	cat $files > $dirsystem/hostapdset
	rm $files
fi

# mpd
crossfade=$( mpc crossfade | cut -d' ' -f2 )
[[ ! -e $dirsystem/mpd-crossfadeset && $crossfade != 0 ]] && echo $crossfade > $dirsystem/mpd-crossfadeset && touch $dirsystem/mpd-crossfade
replaygain=$( grep replaygain /etc/mpd.conf | cut -d'"' -f2 )
[[ ! -e $dirsystem/mpd-replaygainset && $replaygain != off ]] && echo $replaygain > $dirsystem/mpd-replaygainset && touch $dirsystem/mpd-replaygain
buffer=$( grep audio_buffer_size /etc/mpd.conf | cut -d'"' -f2 )
[[ ! -e $dirsystem/mpd-bufferset && -n $buffer ]] && echo $buffer > $dirsystem/mpd-bufferset && $dirsystem/mpd-buffer
bufferoutput=$( grep max_output_buffer_size /etc/mpd.conf | cut -d'"' -f2 )
[[ ! -e $dirsystem/mpd-bufferoutputset && -n $bufferoutput ]] && echo $bufferoutput > $dirsystem/mpd-bufferoutputset && $dirsystem/mpd-bufferoutput

if [[ $( upmpdcli -v 2> /dev/null | cut -d' ' -f2 ) == 1.4.14 ]]; then
	pacman -R --noconfirm libnpupnp libupnpp upmpdcli
	pacman -Sy --noconfirm libnpupnp libupnpp upmpdcli
	systemctl try-restart upmpdcli
fi
grep -q upnpicon.png /etc/upmpdcli.conf.pacsave 2> /dev/null && mv -f /etc/upmpdcli.conf{.pacsave,}

installfinish
