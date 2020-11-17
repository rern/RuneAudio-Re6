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
	if [[ ${args[1]} == true ]]; then
		systemctl enable shairport-sync
		touch $dirsystem/airplay
	else
		systemctl disable shairport-sync
		rm $dirsystem/airplay
	fi
	pushRefresh
	;;
autoplay )
	[[ ${args[1]} == true ]] && touch $dirsystem/autoplay || rm $dirsystem/autoplay
	pushRefresh
	;;
localbrowser )
	if [[ ${args[1]} == true ]]; then
		systemctl enable localbrowser
		touch $dirsystem/localbrowser
		systemctl disable getty@tty1
		sed -i 's/tty1/tty3/' /boot/cmdline.txt
	else
		systemctl disable localbrowser
		rm $dirsystem/localbrowser
		systemctl enable getty@tty1
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
	cp /etc/X11/xinit/xinitrc $dirsystem/xinitrc
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
			systemctl enable mpdscribble@mpd
			touch $dirsystem/mpdscribble
		fi
	else
		systemctl disable mpdscribble@mpd
		rm $dirsystem/mpdscribble
		echo -1
	fi
	pushRefresh
	;;
mpdscribbleset )
	user=${args[1]}
	pwd=${args[2]}
	sed -i -e "s/^\(username =\).*/\1 $user/
	" -e "s/^\(password =\).*/\1 $pwd/
	" /etc/mpdscribble.conf
	echo -e "$user\n$pwd" > $dirsystem/mpdscribble-login
	if systemctl restart mpdscribble@mpd; then
		touch $dirsystem/mpdscribble
	else
		systemctl disable mpdscribble@mpd
		rm $dirsystem/mpdscribble-login
		echo -1
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
screenoff )
	screenoff ${args[1]}
	pushRefresh
	;;
snapcast )
	if [[ ${args[1]} == true ]]; then
		systemctl enable snapserver
		touch $dirsystem/snapcast
	else
		systemctl disable snapserver
		rm $dirsystem/snapcast
	fi
	/srv/http/bash/mpd-conf.sh
	/srv/http/bash/snapcast.sh serverstop
	pushRefresh
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
	if [[ ${args[1]} == true ]]; then
		systemctl enable spotifyd
		touch $dirsystem/spotify
	else
		systemctl disable spotifyd
		rm $dirsystem/spotify
	fi
	pushRefresh
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
	if [[ ${args[1]} == true ]]; then
		systemctl enable upmpdcli
		touch $dirsystem/upnp
	else
		systemctl disable upmpdcli
		rm $dirsystem/upnp
	fi
	pushRefresh
	;;
	
esac
