#!/bin/bash

alias=rre6

. /srv/http/bash/addons.sh

installstart "$1"

getinstallzip

if [[ -e /usr/bin/upmpdcli ]]; then
	pacman -R --noconfirm libnpupnp libupnpp upmpdcli
	pacman -Sy --noconfirm libnpupnp libupnpp upmpdcli
fi

installfinish

restartlocalbrowser
