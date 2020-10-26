#!/bin/bash

alias=rre5

. /srv/http/bash/addons.sh

installstart "$1"

getinstallzip

systemctl restart mpd

if [[ -e /etc/systemd/system/libraryrandom.service ]]; then
	if systemctl is-active libraryrandom; then
		systemctl disable --now libraryrandom
		touch /srv/http/data/system/librandom
	fi
	rm -f /etc/systemd/system/libraryrandom.service /srv/http/bash/libraryrandom.sh
fi

! grep -q ipv6.disable /boot/cmdline.txt && sed -i 's/noop/& ipv6.disable=1/' /boot/cmdline.txt

if ! pacman -Qe python-dbus &> /dev/null; then
	pacman -Sy --noconfirm python-dbus python-gobject
	echo "[Unit]
Description=Bluetooth auto authorization
After=bluetooth.service
Requires=bluetooth.service

[Service]
Type=Idle
ExecStart=/srv/http/bash/bluez-authorize.py
" > /etc/systemd/system/bluez-authorize.service
	sed -i 's/\(aplay.service\).*/\1 bluez-authorize.service/' /etc/systemd/system/bluetooth.service.d/override.conf
	systemctl daemon-reload
	systemctl try-restart bluetooth
fi

file=/etc/systemd/system/bluez-authorize.service
if grep -q bluez_authorize $file; then
	sed -i 's/bluez_authorize/bluez-authorize/' $file
	mv /srv/http/bash/bluez{_,-}authorize.py
	systemctl daemon-reload
	systemctl try-restart bluetooth
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

installfinish

restartlocalbrowser
