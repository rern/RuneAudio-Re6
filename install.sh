#!/bin/bash

alias=rre6

. /srv/http/bash/addons.sh

installstart "$1"

getinstallzip

[[ -e /usr/bin/upmpdcli ]] && pacman -R --noconfirm libnpupnp libupnpp upmpdcli
pacman -Sy --noconfirm libnpupnp libupnpp upmpdcli

installfinish

restartlocalbrowser
