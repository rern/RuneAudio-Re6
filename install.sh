#!/bin/bash

alias=rre5

. /srv/http/bash/addons.sh

installstart "$1"

if [[ -e /usr/bin/bluetoothctl && ! -e /etc/systemd/system/bluez-authorize.service ]]; then
	pacman -Sy python-dbus python-gobject
	echo '[Unit]
Description=Bluetooth auto authorization
After=bluetooth.service
Requires=bluetooth.service

[Service]
Type=Idle
ExecStart=/srv/http/bash/bluez_authorize.py' > /etc/systemd/system/bluez-authorize.service
	sed -i '/BindsTo/ s/$/ bluez-authorize.service/' /etc/systemd/system/bluetooth.service.d/override.conf
	systemctl daemon-reload
	systemctl try-restart bluetooth
fi

getinstallzip

installfinish

restartlocalbrowser
