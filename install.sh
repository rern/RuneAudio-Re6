#!/bin/bash

alias=rre6

. /srv/http/bash/addons.sh

installstart "$1"

getinstallzip

if [[ $( upmpdcli -v 2> /dev/null | cut -d' ' -f2 ) == 1.4.14 ]]; then
	pacman -R --noconfirm libnpupnp libupnpp upmpdcli
	pacman -Sy --noconfirm libnpupnp libupnpp upmpdcli
fi

installfinish

restartlocalbrowser
