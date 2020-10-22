#!/bin/bash

dirsystem=/srv/http/data/system
filebootlog=/srv/http/data/shm/bootlog
filereboot=/srv/http/data/shm/reboot

# convert each line to each args
readarray -t args <<< "$1"

pushRefresh() {
	curl -s -X POST http://127.0.0.1/pub?id=refresh -d '{ "page": "system" }'
}

case ${args[0]} in

bluetooth )
	if [[ ${args[1]} == true ]]; then
		sed -i '$ a\dtparam=krnbt=on' /boot/config.txt
		systemctl enable --now bluetooth
		echo "${args[2]}" > $filereboot
		touch $dirsystem/onboard-bluetooth
	else
		sed -i '/dtparam=krnbt=on/ d' /boot/config.txt
		systemctl disable --now bluetooth
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
statusbootlog )
	if [[ -e $filebootlog ]]; then
		cat $filebootlog
	else
		log=$( journalctl -b | sed -n '1,/Startup finished.*kernel/ p' )
		finish=$( sed 's/.*\(Startup.*\)/\1/' <<< ${log##*$'\n'} )
		echo "$finish<hr>$log" | tee $filebootlog
	fi
	;;
statusonboard )
	ifconfig
	if systemctl -q is-active bluetooth; then
		echo '<hr>'
		bluetoothctl show | sed 's/^\(Controller.*\)/bluetooth: \1/'
	fi
	;;
timezone )
	timezone=${args[1]}
	timedatectl set-timezone $timezone
	echo $timezone > $dirsystem/timezone
	pushRefresh
	;;
wlan )
	if [[ ${args[1]} == true ]]; then
		modprobe brcmfmac
		systemctl enable --now netctl-auto@wlan0
		touch $dirsystem/onboard-wlan
	else
		systemctl disable --now netctl-auto@wlan0
		rm $dirsystem/onboard-wlan
		rmmod brcmfmac
	fi
	pushRefresh
	;;
	
esac
