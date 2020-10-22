#!/bin/bash

alias=rre5

. /srv/http/bash/addons.sh

installstart "$1"

file=/etc/systemd/system/bluez-authorize.service
if [[ -e /usr/bin/bluetoothctl && ! -e $file ]]; then
	bt=1
	pacman -Sy python-dbus python-gobject
	echo "[Unit]
Description=Bluetooth auto authorization
After=bluetooth.service
Requires=bluetooth.service

[Service]
Type=Idle
ExecStart=/srv/http/bash/bluez_authorize.py
" > $file
	sed -i 's/\(aplay.service\).*/\1 bluez-authorize.service/' /etc/systemd/system/bluetooth.service.d/override.conf
fi

file=/etc/systemd/system/wlan0-powersaveoff.service
if [[ ! -e $file ]]; then
	echo "[Unit]
Description=Set WiFi power save off
After=sys-subsystem-net-devices-wlan0.device

[Service]
Type=oneshot
ExecStart=/usr/bin/iw wlan0 set power_save off

[Install]
WantedBy=sys-subsystem-net-devices-wlan0.device
" > $file
	systemctl enable wlan0-powersaveoff
fi

getinstallzip

if [[ -n $bt ]]; then
	systemctl daemon-reload
	systemctl try-restart bluetooth
fi

installfinish

restartlocalbrowser
