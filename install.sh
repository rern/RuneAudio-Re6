#!/bin/bash

alias=rre6

. /srv/http/bash/addons.sh

installstart "$1"

getinstallzip

file=/srv/http/data/system/mpd-soxrset
[[ ! -e $file ]] && cat <<[-]EOF > $file
	quality        "custom"
	threads        "1"
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
