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

airplay )
	[[ ${args[1]} == true ]] && enable shairport-sync airplay || disable shairport-sync airplay
	;;
autoplay )
	[[ ${args[1]} == true ]] && touch $dirsystem/autoplay || rm $dirsystem/autoplay
	pushRefresh
	;;
bluetooth )
	if [[ ${args[1]} == true ]]; then
		sed -i '$ a\dtparam=krnbt=on' /boot/config.txt
		if lsmod | grep -q bluetooth; then
			systemctl enable --now bluetooth bluealsa
		else
			systemctl enable bluetooth bluealsa
			echo "${args[2]}" > $filereboot
		fi
		touch $dirsystem/onboard-bluetooth
	else
		sed -i '/dtparam=krnbt=on/ d' /boot/config.txt
		systemctl disable --now bluetooth bluealsa
		rm $dirsystem/onboard-bluetooth
	fi
	pushRefresh
	;;
hostname )
	hostname=${args[1]}
	hostnamectl set-hostname $hostname
	sed -i "s/\(--hostname \).*/\1${args[1]}/" /etc/systemd/system/wsdd.service
	sed -i "s/^\(ssid=\).*/\1${args[1]}/" /etc/hostapd/hostapd.conf
	sed -i '/^\tname =/ s/".*"/"'$hostname'"/' /etc/shairport-sync.conf
	sed -i "s/^\(friendlyname = \).*/\1${args[1]}/" /etc/upmpdcli.conf
	rm -f /root/.config/chromium/SingletonLock
	systemctl daemon-reload
	systemctl try-restart avahi-daemon hostapd mpd smb wsdd shairport-sync shairport-meta upmpdcli
	systemctl -q is-active bluetooth && bluetoothctl system-alias $hostname
	echo $hostname > $dirsystem/hostname
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
i2smodule )
	aplayname=${args[1]}
	output=${args[2]}
	reboot=${args[3]}
	dtoverlay=$( grep 'dtparam=krnbt=on\|dtoverlay=gpio\|dtoverlay=sdtweak,poll_once' /boot/config.txt )
	sed -i '/dtparam=\|dtoverlay=\|^$/ d' /boot/config.txt
	[[ -n $dtoverlay ]] && sed -i '$ r /dev/stdin' /boot/config.txt <<< "$dtoverlay"
	if [[ ${aplayname:0:7} != bcm2835 ]]; then
		lines="\
dtparam=audio=off
dtparam=i2s=on
dtoverlay=${args[1]}"
		sed -i '$ r /dev/stdin' /boot/config.txt <<< "$lines"
		rm -f $dirsystem/onboard-audio
	else
		sed -i '$ a\dtparam=audio=on' /boot/config.txt
		touch $dirsystem/onboard-audio
	fi
	echo $aplayname > $dirsystem/audio-aplayname
	echo $output > $dirsystem/audio-output
	echo "$reboot" > $filereboot
	pushRefresh
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
	sed -i -e 's/\(-use_cursor \).*/\1"'$cursor'" \&/
	' -e 's/\(xset dpms 0 0 \).*/\1"'$screenoff'" \&/
	' -e 's/\(factor=\).*/\1"'$zoom'"/
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
onboardaudio )
	if [[ ${args[1]} == true ]]; then
		onoff=on
		touch $dirsystem/onboard-audio
	else
		onoff=off
		rm $dirsystem/onboard-audio
	fi
	sed -i "s/\(dtparam=audio=\).*/\1$onoff/" /boot/config.txt
	echo "${args[2]}" > $filereboot
	pushRefresh
	;;
regional )
	ntp=${args[1]}
	regom=${args[2]}
	sed -i "s/^\(NTP=\).*/\1$ntp/" /etc/systemd/timesyncd.conf
	sed -i 's/".*"/"'$regdom'"/' /etc/conf.d/wireless-regdom
	iw reg set $regdom
	[[ $ntp == pool.ntp.org ]] && rm $dirsystem/ntp || echo $ntp > $dirsystem/ntp
	[[ $regdom == 00 ]] && rm $dirsystem/wlanregdom || echo $regdom > $dirsystem/wlanregdom
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
soundprofile )
	if [[ ${args[1]} == true ]]; then
		[[ -e $dirsystem/soundprofile-custom ]] && profile=custom || profile=RuneAudio
		echo $profile > $dirsystem/soundprofile
	else
		profile=default
		rm $dirsystem/soundprofile
	fi
	/srv/http/bash/cmd.sh soundprofile$'\n'"$profile"
	pushRefresh
	;;
soundprofileset )
	profile=${args[1]}
	values=${args[2]}
	customfile=$dirsystem/soundprofile-custom
	echo $profile > $dirsystem/soundprofile
	[[ -n $value ]] && echo $values > $customfile
	[[ $profile == 'custom' && ! -e $customfile ]] && echo 1500 1000 60 18000000 > $customfile
	/srv/http/bash/cmd.sh soundprofile$'\n'"$profile"
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
statusbootlog )
	if [[ -e $filebootlog ]]; then
		cat $filebootlog
	else
		log=$( journalctl -b | sed -n '1,/Startup finished.*kernel/ p' )
		finish=$( sed 's/.*\(Startup.*\)/\1/' <<< ${log##*$'\n'} )
		echo "$finish<hr>$log" | tee $filebootlog
	fi
	;;
streaming )
	[[ ${args[1]} == true ]] && touch $dirsystem/streaming || rm $dirsystem/streaming
	pushRefresh
	/srv/http/bash/mpd-conf.sh
	;;
timezone )
	timezone=${args[1]}
	timedatectl set-timezone $timezone
	echo $timezone > $dirsystem/timezone
	pushRefresh
	;;
upnp )
	[[ ${args[1]} == true ]] && enable upmpdcli upnp || disable upmpdcli upnp
	;;
wlan )
	if [[ ${args[1]} == true ]]; then
		modprobe brcmfmac
		enable netctl-auto@wlan0 onboard-wlan
	else
		disable netctl-auto@wlan0 onboard-wlan
		rmmod brcmfmac
	fi
	pushRefresh
	;;
	
esac
