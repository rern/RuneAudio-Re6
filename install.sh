#!/bin/bash

alias=rre6

. /srv/http/bash/addons.sh

installstart "$1"

getinstallzip

dirsystem=/srv/http/data/system

rm -f $dirsystem/soundprofile

[[ -e $dirsystem/spotify-device ]] && cp $dirsystem/spotify{-device,set}

files=$dirsystem/{accesspoint-ip,accesspoint-iprange,accesspoint-passphrase}
if [[ -e $dirsystem/accesspoint-ip ]]; then
	cat $files > $dirsystem/accesspointset
	rm $files
fi

mv $dirsystem/mpdscribble{-login,set} &> /dev/null

files=$dirsystem/{ntp,wlanregdom}
if [[ -e $dirsystem/ntp ]]; then
	cat $files > $dirsystem/regional
	rm $files
fi

files=$dirsystem/{snapcast-latency,snapserverpw}
if [[ -e $dirsystem/snapcast-latency ]]; then
	cat $files > $dirsystem/snapclientset
	rm $files
fi

file=$dirsystem/mpd-soxrset
[[ ! -e $file ]] && cat <<[-]EOF > $file
	quality        "custom"
	precision      "20"
	phase_response "50"
	passband_end   "91.3"
	stopband_begin "100"
	attenuation    "0"
	flags          "0"
}
[-]EOF

if [[ $( upmpdcli -v 2> /dev/null | cut -d' ' -f2 ) == 1.4.14 ]]; then
	pacman -R --noconfirm libnpupnp libupnpp upmpdcli
	pacman -Sy --noconfirm libnpupnp libupnpp upmpdcli
	systemctl try-restart upmpdcli
fi
grep -q upnpicon.png /etc/upmpdcli.conf.pacsave 2> /dev/null && mv -f /etc/upmpdcli.conf{.pacsave,}

installfinish
