#!/bin/bash

alias=rre6

. /srv/http/bash/addons.sh

installstart "$1"

getinstallzip

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

dirsystem=/srv/http/data/system

# system
mv /srv/http/data/system/{gpio,relays} &> /dev/null
files=$dirsystem/{ntp,wlanregdom}
if [[ -e $dirsystem/ntp ]]; then
	cat $files > $dirsystem/regional
	rm $files
fi
rm -f $dirsystem/soundprofile

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
if [[ -e $dirsystem/localbrowser ]]; then
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
[[ $crossfade != 0 ]] && echo $crossfade > $dirsystem/mpd-crossfadeset
replaygain=$( grep replaygain /etc/mpd.conf | cut -d'"' -f2 )
[[ -n $replaygain ]] && echo $replaygain > $dirsystem/mpd-replaygainset
buffer=$( grep audio_buffer_size /etc/mpd.conf | cut -d'"' -f2 )
[[ -n $buffer ]] && echo $buffer > $dirsystem/mpd-bufferset
bufferoutput=$( grep max_output_buffer_size /etc/mpd.conf | cut -d'"' -f2 )
[[ -n $bufferoutput ]] && echo $bufferoutput > $dirsystem/mpd-bufferoutputset

if [[ $( upmpdcli -v 2> /dev/null | cut -d' ' -f2 ) == 1.4.14 ]]; then
	pacman -R --noconfirm libnpupnp libupnpp upmpdcli
	pacman -Sy --noconfirm libnpupnp libupnpp upmpdcli
	systemctl try-restart upmpdcli
fi
grep -q upnpicon.png /etc/upmpdcli.conf.pacsave 2> /dev/null && mv -f /etc/upmpdcli.conf{.pacsave,}

installfinish
