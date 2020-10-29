#!/bin/bash

dirsystem=/srv/http/data/system
filebootlog=/srv/http/data/shm/bootlog
filereboot=/srv/http/data/shm/reboot

# convert each line to each args
readarray -t args <<< "$1"

pushRefresh() {
	curl -s -X POST http://127.0.0.1/pub?id=refresh -d '{ "page": "system" }'
}
enable() {
	if systemctl start $1; then
		systemctl enable $1
		touch $dirsystem/$2
		pushRefresh
	fi
}
disable() {
	systemctl disable --now $1
	rm $dirsystem/$2
	pushRefresh
}

case ${args[0]} in

accesspoint )
	if [[ ${args[1]} == true ]]; then
		netctl stop-all
		ifconfig wlan0 ${args[2]}
		systemctl enable --now hostapd dnsmasq
		touch $dirsystem/accesspoint
	else
		systemctl disable --now hostapd dnsmasq
		rm $dirsystem/accesspoint
		ifconfig wlan0 0.0.0.0
	fi
	pushRefresh
	;;
accesspointset )
	iprange=${args[1]}
	router=${args[2]}
	password=${args[3]}
	sed -i -e "s/^\(dhcp-range=\).*/\1$iprange/
" -e "s/^\(.*option:router,\).*/\1$router/
" -e "s/^\(.*option:dns-server,\).*/\1$router/
" /etc/dnsmasq.conf
	sed -i -e '/wpa\|rsn_pairwise/ s/^#\+//
' -e "s/\(wpa_passphrase=\).*/\1$password/
" /etc/hostapd/hostapd.conf
	systemctl restart hostapd dnsmasq
	if [[ $router == 192.168.5.1 ]]; then
		rm $dirsystem/accesspoint-ip*
	else
		echo $router > $dirsystem/accesspoint-ip
		echo $iprange > $dirsystem/accesspoint-iprange
	fi
	if [[ $password == RuneAudio ]]; then
		rm $dirsystem/accesspoint-passphrase
	else
		echo $password > $dirsystem/accesspoint-passphrase
	fi
	pushRefresh
	;;
airplay )
	[[ ${args[1]} == true ]] && enable shairport-sync airplay || disable shairport-sync airplay
	;;
autoplay )
	[[ ${args[1]} == true ]] && touch $dirsystem/autoplay || rm $dirsystem/autoplay
	pushRefresh
	;;
gpio )
	enable=${args[1]}
	if [[ $enable == true ]]; then
		touch $dirsystem/gpio
	else
		rm $dirsystem/gpio
	fi
	;;
lcdrotate )
	degree=${args[1]}
	sed -i "s/\(tft35a\).*/\1:rotate=$degree/" /boot/config.txt
	echo Rotate GPIO LCD screen > /srv/http/data/shm/reboot
	;;
localbrowser )
	if [[ ${args[1]} == true ]]; then
		enable localbrowser localbrowser
		systemctl disable getty@tty1
		sed -i 's/\(console=\).*/\1tty3 plymouth.enable=0 quiet loglevel=0 logo.nologo vt.global_cursor_default=0/' /boot/cmdline.txt
	else
		disable localbrowser localbrowser
		systemctl enable getty@tty1
		sed -i 's/\(console=\).*/\1tty1/' /boot/cmdline.txt
		/srv/http/bash/ply-image /srv/http/assets/img/splash.png
	fi
	pushRefresh
	;;
localbrowserset )
	rotate=${args[1]}
	cursor=${args[2]}
	screenoff=${args[3]}
	zoom=${args[4]}
	path=$dirsystem/localbrowser
	rotateconf=/etc/X11/xorg.conf.d/99-raspi-rotate.conf
	if [[ $rotate == NORMAL ]]; then
		rm -f $rotateconf $path-rotatefile
	else
		case $rotate in
			CW )  matrix='0 1 0 -1 0 1 0 0 1';;
			CCW ) matrix='0 -1 1 1 0 0 0 0 1';;
			UD )  matrix='-1 0 1 0 -1 1 0 0 1';;
		esac
		sed -e "s/ROTATION_SETTING/$rotate/
		" -e "s/MATRIX_SETTING/$matrix/" /etc/X11/xinit/rotateconf | tee $rotateconf $path-rotatefile
	fi
	ln -sf /srv/http/assets/img/{$rotate,splash}.png
	if [[ $cursor == true ]]; then
		touch $path-cursor
		cursor=yes
	else
		rm $path-cursor
		cursor=no
	fi
	[[ $screenoff != 0 ]] && echo $screenoff > $path-screenoff || rm $path-screenoff
	[[ $zoom != 1 ]] && echo $zoom > $path-zoom || rm $path-zoom
	sed -i -e 's/\(-use_cursor \).*/\1'$cursor' \&/
	' -e 's/\(xset dpms 0 0 \).*/\1'$screenoff' \&/
	' -e 's/\(factor=\).*/\1'$zoom'/
	' /etc/X11/xinit/xinitrc
	systemctl restart localbrowser
	pushRefresh
	;;
login )
	if [[ ${args[1]} == true ]]; then
		touch $dirsystem/login
		ip=127.0.0.1
	else
		rm $dirsystem/login
		ip=0.0.0.0
	fi
	sed -i '/^bind_to_address/ s/".*"/"'$ip'"/' /etc/mpd.conf
	systemctl restart mpd
	pushRefresh
	;;
mpdscribble )
	if [[ ${args[1]} == true ]]; then
		if systemctl start mpdscribble; then
			systemctl enable mpdscribble
			touch $dirsystem/mpdscribble
		fi
	else
		disable mpdscribble@mpd mpdscribble
		echo -1
	fi
	;;
mpdscribbleset )
	sed -i -e "s/^\(username =\).*/\1 ${args[1]}/
	" -e "s/^\(password =\).*/\1 ${args[2]}/
	" /etc/mpdscribble.conf
	echo -e "${args[1]}\n${args[2]}" > $dirsystem/mpdscribble-login
	if systemctl restart mpdscribble@mpd; then
		touch $dirsystem/mpdscribble
	else
		systemctl disable mpdscribble@mpd
		rm $dirsystem/mpdscribble-login
		echo -1
	fi
	pushRefresh
	;;
samba )
	if [[ ${args[1]} == true ]]; then
		systemctl enable --now wsdd smb
	else
		systemctl disable --now smb wsdd
	fi
	;;
sambaset )
	smbconf=/etc/samba/smb.conf
	sed -i '/read only = no/ d' $smbconf
	rm -f $dirsystem/samba-*
	if [[ ${args[1]} == true ]]; then
		sed -i '/path = .*SD/ a\tread only = no' $smbconf
		touch $dirsystem/samba-readonlysd
	fi
	if [[ ${args[2]} == true ]]; then
		sed -i '/path = .*USB/ a\tread only = no' $smbconf
		touch $dirsystem/samba-readonlyusb
	fi
	systemctl restart smb wsdd
	pushRefresh
	;;
snapcast )
	[[ ${args[1]} == true ]] && enable snapserver snapcast || disable snapserver snapcast
	/srv/http/bash/mpd-conf.sh
	/srv/http/bash/snapcast.sh serverstop
	;;
snapclient )
	[[ ${args[1]} == true ]] && touch $dirsystem/snapclient || rm $dirsystem/snapclient
	pushRefresh
	;;
snapclientset )
	latency=${args[1]}
	pwd=${args[2]}
	sed -i '/OPTS=/ s/".*"/"--latency="'$latency'"/' /etc/default/snapclient
	systemctl restart snapclient
	echo $latency > $dirsystem/snapcast-latency
	[[ $pwd == rune ]] && rm -f $dirsystem/snapserverpw || echo $pwd > $dirsystem/snapserverpw
	pushRefresh
	;;
spotify )
	[[ ${args[1]} == true ]] && enable spotifyd spotify || disable spotifyd spotify
	;;
spotifyset )
	device=${args[1]}
	sed -i "s/^\(device = \)/\1$device/" /etc/spotifyd.conf
	systemctl restart spotifyd
	echo $device > $dirsystem/spotify-device
	pushRefresh
	;;
streaming )
	[[ ${args[1]} == true ]] && touch $dirsystem/streaming || rm $dirsystem/streaming
	pushRefresh
	/srv/http/bash/mpd-conf.sh
	;;
upnp )
	[[ ${args[1]} == true ]] && enable upmpdcli upnp || disable upmpdcli upnp
	;;
	
esac
