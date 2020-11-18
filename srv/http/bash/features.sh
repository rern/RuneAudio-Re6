#!/bin/bash

dirsystem=/srv/http/data/system
filebootlog=/srv/http/data/shm/bootlog
filereboot=/srv/http/data/shm/reboot

# convert each line to each args
readarray -t args <<< "$1"

pushRefresh() {
	curl -s -X POST http://127.0.0.1/pub?id=refresh -d '{ "page": "system" }'
}

rotate() {
	rotate=$1
	rotateconf=/etc/X11/xorg.conf.d/99-raspi-rotate.conf
	if [[ $rotate == NORMAL ]]; then
		rm -f $rotateconf $dirsystem/rotatefile
	else
		case $rotate in
			CW )  matrix='0 1 0 -1 0 1 0 0 1';;
			CCW ) matrix='0 -1 1 1 0 0 0 0 1';;
			UD )  matrix='-1 0 1 0 -1 1 0 0 1';;
		esac
		sed -e "s/ROTATION_SETTING/$rotate/
		" -e "s/MATRIX_SETTING/$matrix/" $rotateconf | tee $rotateconf $dirsystem/rotatefile
	fi
	ln -sf /srv/http/assets/img/{$rotate,splash}.png
}
rotatelcd() {
	degree=$1
	sed -i "s/\(tft35a\).*/\1:rotate=$degree/" /boot/config.txt
	cp -f /etc/X11/{lcd$degree,xorg.conf.d/99-calibration.conf}
	(( $degree != 0 )) && cp -f /etc/X11/xorg.conf.d/99-calibration.conf $dirsystem/calibration
	echo Rotate GPIO LCD screen > /srv/http/data/shm/reboot
}
screenoff() {
	sec=$1
	if [[ $sec == 0 ]]; then
		sed -i -e '/xset/ d
' -e '/export DISPLAY/ a\
xset dpms 0 0 0\
xset s off\
xset -dpms
' /etc/X11/xinit/xinitrc
		DISPLAY=:0 xset dpms 0 0 0
	else
		sed -i -e '/xset/ d
' -e "/export DISPLAY/ a\
xset dpms $sec $sec $sec
" /etc/X11/xinit/xinitrc
		DISPLAY=:0 xset dpms $sec $sec $sec
	fi
	cp /etc/X11/xinit/xinitrc $dirsystem/xinitrc
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
		rm -f $dirsystem/accesspoint
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
	systemctl try-restart hostapd dnsmasq
	printf '%s\n' "${args[@]:1}" > $dirsystem/lcdcharset
	pushRefresh
	;;
airplay )
	if [[ ${args[1]} == true ]]; then
		systemctl enable --now shairport-sync
		touch $dirsystem/airplay
	else
		systemctl disable --now shairport-sync
		rm -f $dirsystem/airplay
	fi
	pushRefresh
	;;
aplaydevices )
	aplay -L | grep -v '^\s\|^null' | head -c -1
	;;
autoplay )
	[[ ${args[1]} == true ]] && touch $dirsystem/autoplay || rm -f $dirsystem/autoplay
	pushRefresh
	;;
localbrowser )
	if [[ ${args[1]} == true ]]; then
		systemctl enable --now localbrowser
		touch $dirsystem/localbrowser
		systemctl disable --now getty@tty1
		sed -i 's/tty1/tty3/' /boot/cmdline.txt
	else
		systemctl disable --now localbrowser
		rm -f $dirsystem/localbrowser
		systemctl enable --now getty@tty1
		sed -i 's/tty3/tty1/' /boot/cmdline.txt
		/srv/http/bash/ply-image /srv/http/assets/img/splash.png
	fi
	pushRefresh
	;;
localbrowserset )
	rotate=${args[1]}
	screenoff=${args[2]}
	cursor=${args[3]}
	zoom=${args[4]}
	path=$dirsystem/localbrowser
	
	if [[ -n $rotate ]]; then
		[[ $rotate =~ ^(0|90|180|270)$ ]] && rotatelcd $rotate || rotate $rotate
	fi
	[[ -n $screenoff ]] && screenoff $screenoff
	[[ $cursor == true ]] && cursor=yes || cursor=no
	sed -i -e 's/\(-use_cursor \).*/\1'$cursor' \&/
' -e 's/\(factor=\).*/\1'$zoom'/
' /etc/X11/xinit/xinitrc
	systemctl try-restart localbrowser
	printf '%s\n' "${args[@]:1}" > $dirsystem/localbrowserset
	pushRefresh
	;;
login )
	if [[ ${args[1]} == true ]]; then
		touch $dirsystem/login
		ip=127.0.0.1
	else
		rm -f $dirsystem/login
		ip=0.0.0.0
	fi
	sed -i '/^bind_to_address/ s/".*"/"'$ip'"/' /etc/mpd.conf
	systemctl restart mpd
	pushRefresh
	;;
mpdscribbledisable )
	systemctl disable --now mpdscribble@mpd
	rm -f $dirsystem/mpdscribble
	pushRefresh
	;;
mpdscribbleset )
	user=${args[1]}
	pwd=${args[2]}
	sed -i -e "s/^\(username =\).*/\1 $user/
	" -e "s/^\(password =\).*/\1 $pwd/
	" /etc/mpdscribble.conf
	if systemctl try-restart mpdscribble@mpd; then
		systemctl enable mpdscribble@mpd
		printf '%s\n' "${args[@]:1}" > $dirsystem/mpdscribbleset
	else
		systemctl disable mpdscribble@mpd
	fi
	pushRefresh
	;;
rotate )
	rotate ${args[1]}
	pushRefresh
	;;
rotatelcd )
	rotatelcd ${args[1]}
	pushRefresh
	;;
samba )
	if [[ ${args[1]} == true ]]; then
		systemctl enable --now wsdd smb
	else
		systemctl disable --now smb wsdd
	fi
	pushRefresh
	;;
sambaset )
	smbconf=/etc/samba/smb.conf
	sed -i '/read only = no/ d' $smbconf
	rm -f $dirsystem/samba-*
	[[ ${args[1]} == true ]] && sed -i '/path = .*SD/ a\tread only = no' $smbconf
	[[ ${args[2]} == true ]] && sed -i '/path = .*USB/ a\tread only = no' $smbconf
	systemctl try-restart smb wsdd
	printf '%s\n' "${args[@]:1}" > $dirsystem/sambaset
	pushRefresh
	;;
screenoff )
	screenoff ${args[1]}
	pushRefresh
	;;
snapcast )
	if [[ ${args[1]} == true ]]; then
		systemctl enable --now snapserver
		touch $dirsystem/snapcast
	else
		systemctl disable --now snapserver
		rm -f $dirsystem/snapcast
	fi
	/srv/http/bash/mpd-conf.sh
	/srv/http/bash/snapcast.sh serverstop
	pushRefresh
	;;
snapclient )
	[[ ${args[1]} == true ]] && touch $dirsystem/snapclient || rm -f $dirsystem/snapclient
	pushRefresh
	;;
snapclientset )
	latency=${args[1]}
	pwd=${args[2]}
	sed -i '/OPTS=/ s/".*"/"--latency="'$latency'"/' /etc/default/snapclient
	systemctl try-restart snapclient
	printf '%s\n' "${args[@]:1}" > $dirsystem/snapclientset
	pushRefresh
	;;
spotify )
	if [[ ${args[1]} == true ]]; then
		systemctl enable --now spotifyd
		touch $dirsystem/spotify
	else
		systemctl disable --now spotifyd
		rm -f $dirsystem/spotify
	fi
	pushRefresh
	;;
spotifyset )
	device=${args[1]}
	sed -i "s/^\(device = \)/\1$device/" /etc/spotifyd.conf
	systemctl try-restart spotifyd
	echo $device > $dirsystem/spotifyset
	pushRefresh
	;;
streaming )
	[[ ${args[1]} == true ]] && touch $dirsystem/streaming || rm -f $dirsystem/streaming
	pushRefresh
	/srv/http/bash/mpd-conf.sh
	;;
upnp )
	if [[ ${args[1]} == true ]]; then
		systemctl enable --now upmpdcli
		touch $dirsystem/upnp
	else
		systemctl disable --now upmpdcli
		rm -f $dirsystem/upnp
	fi
	pushRefresh
	;;
	
esac
