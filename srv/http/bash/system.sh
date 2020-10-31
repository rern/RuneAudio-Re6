#!/bin/bash

dirdata=/srv/http/data
dirsystem=$dirdata/system
dirtmp=$dirdata/shm
filebootlog=$dirtmp/bootlog
filereboot=$dirtmp/reboot

# convert each line to each args
readarray -t args <<< "$1"

pushRefresh() {
	curl -s -X POST http://127.0.0.1/pub?id=refresh -d '{ "page": "system" }'
}

case ${args[0]} in

btdiscoverable )
	yesno=${args[1]}
	bluetoothctl discoverable $yesno
	if [[ $yesno == yes ]]; then
		rm -f $dirsystem/btdiscoverno
	else
		touch $dirsystem/btdiscoverno
	fi
	;;
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
databackup )
	backupfile=$dirdata/tmp/backup.gz
	rm -f $backupfile
	cp {/etc/X11/xorg.conf.d,$dirdata/system}/99-calibration.conf
	cp {/etc/X11/xinit,$dirdata/system}/xinitrc
	bsdtar \
		--exclude './addons' \
		--exclude './embedded' \
		--exclude './shm' \
		--exclude './system/version' \
		--exclude './tmp' \
		-czf $backupfile \
		-C /srv/http \
		data \
		2> /dev/null && echo 1
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
	dtoverlay=$( grep 'dtparam=i2c_arm=on\|dtparam=krnbt=on\|dtparam=spi=on\|dtoverlay=gpio\|dtoverlay=sdtweak,poll_once\|dtoverlay=tft35a\|hdmi_force_hotplug=1' /boot/config.txt )
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
lcd )
	enable=${args[1]}
	if [[ $enable == true ]]; then
		echo -n "\
hdmi_force_hotplug=1
dtparam=i2c_arm=on
dtparam=spi=on
dtoverlay=tft35a:rotate=0
" >> /boot/config.txt
		echo -n "\
i2c-bcm2708
i2c-dev
" >> /etc/modules-load.d/raspberrypi.conf
		sed -i 's/fb0/fb1/' /etc/X11/xorg.conf.d/99-fbturbo.conf
		touch $dirsystem/lcd
	else
		sed -i '/hdmi_force_hotplug\|i2c_arm=on\|spi=on\|tft35a/ d' /boot/config.txt
		sed -i '/i2c-bcm2708\|i2c-dev/ d' /etc/modules-load.d/raspberrypi.conf
		sed -i 's/fb1/fb0/' /etc/X11/xorg.conf.d/99-fbturbo.conf
		rm $dirsystem/lcd
	fi
	;;
lcdcalibrate )
	touch /srv/http/data/shm/calibrate
	degree=$( grep rotate /boot/config.txt | cut -d= -f3 )
	cp -f /etc/X11/{lcd$degree,xorg.conf.d/99-calibration.conf}
	systemctl restart localbrowser
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
