#!/bin/bash


dirdata=/srv/http/data
dirsystem=$dirdata/system
dirtmp=$dirdata/shm
filebootlog=$dirtmp/bootlog
filereboot=$dirtmp/reboot
fileconfig=/boot/config.txt
filemodule=/etc/modules-load.d/raspberrypi.conf

# convert each line to each args
readarray -t args <<< "$1"

pushRefresh() {
	curl -s -X POST http://127.0.0.1/pub?id=refresh -d '{ "page": "system" }'
}
soundprofile() { # latency swapiness mtu txtqueuelen
	val=( $1 )
	sysctl kernel.sched_latency_ns=${val[0]}
	sysctl vm.swappiness=${val[1]}
	if ifconfig | grep -q eth0; then
		ip link set eth0 mtu ${val[2]}
		ip link set eth0 txqueuelen ${val[3]}
	fi
}

case ${args[0]} in

bluetoothdisable )
	sed -i '/dtparam=krnbt=on/ d' $fileconfig
	systemctl disable --now bluetooth
	rm -f $dirsystem/onboard-bluetooth
	pushRefresh
	;;
bluetoothset )
	[[ ${args[1]} == true ]] && yesno=yes || yesno=no
	if ! grep -q 'dtparam=krnbt=on' $fileconfig; then
		sed -i '$ a\dtparam=krnbt=on' $fileconfig
		echo "${args[2]}" > $filereboot
		systemctl enable bluetooth
	else
		systemctl enable --now bluetooth
		bluetoothctl discoverable $yesno
	fi
	touch $dirsystem/onboard-bluetooth
	echo $yesno > $dirsystem/bluetoothset
	sleep 3
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
	systemctl try-restart avahi-daemon hostapd mpd smb shairport-sync shairport-meta upmpdcli
	systemctl -q is-active bluetooth && bluetoothctl system-alias $hostname
	echo $hostname > $dirsystem/hostname
	pushRefresh
	;;
i2smodule )
	aplayname=${args[1]}
	output=${args[2]}
	reboot=${args[3]}
	dtoverlay=$( grep 'dtparam=i2c_arm=on\|dtparam=krnbt=on\|dtparam=spi=on\|dtoverlay=gpio\|dtoverlay=sdtweak,poll_once\|dtoverlay=tft35a\|hdmi_force_hotplug=1' $fileconfig )
	sed -i '/dtparam=\|dtoverlay=\|^$/ d' $fileconfig
	[[ -n $dtoverlay ]] && sed -i '$ r /dev/stdin' $fileconfig <<< "$dtoverlay"
	if [[ ${aplayname:0:7} != bcm2835 ]]; then
		lines="\
dtparam=audio=off
dtparam=i2s=on
dtoverlay=${args[1]}"
		sed -i '$ r /dev/stdin' $fileconfig <<< "$lines"
		rm -f $dirsystem/onboard-audio
	else
		sed -i '$ a\dtparam=audio=on' $fileconfig
		touch $dirsystem/onboard-audio
	fi
	echo $aplayname > $dirsystem/audio-aplayname
	echo $output > $dirsystem/audio-output
	echo "$reboot" > $filereboot
	pushRefresh
	;;
lcd )
	enable=${args[1]}
	reboot=${args[2]}
	if [[ $enable == true ]]; then
		sed -i '1 s/$/ fbcon=map:10 fbcon=font:ProFont6x11/' /boot/cmdline.txt
		config="\
hdmi_force_hotplug=1
dtparam=spi=on
dtoverlay=tft35a:rotate=0"
		! grep -q 'dtparam=i2c_arm=on' $fileconfig && config+="
dtparam=i2c_arm=on"
		echo -n "$config" >> $fileconfig
		! grep -q 'i2c-bcm2708' $filemodule && echo -n "\
i2c-bcm2708
i2c-dev
" >> $filemodule
		cp -f /etc/X11/{lcd0,xorg.conf.d/99-calibration.conf}
		sed -i 's/fb0/fb1/' /etc/X11/xorg.conf.d/99-fbturbo.conf
		touch $dirsystem/lcd
	else
		sed -i '1 s/ fbcon=map:10 fbcon=font:ProFont6x11//' /boot/cmdline.txt
		sed -i '/hdmi_force_hotplug\|i2c_arm=on\|spi=on\|tft35a/ d' $fileconfig
		sed -i '/i2c-bcm2708\|i2c-dev/ d' $filemodule
		sed -i 's/fb1/fb0/' /etc/X11/xorg.conf.d/99-fbturbo.conf
		rm -f $dirsystem/lcd
	fi
	echo "$reboot" > $filereboot
	pushRefresh
	;;
lcdcalibrate )
	degree=$( grep rotate $fileconfig | cut -d= -f3 )
	cp -f /etc/X11/{lcd$degree,xorg.conf.d/99-calibration.conf}
	systemctl stop localbrowser
	value=$( DISPLAY=:0 xinput_calibrator | grep Calibration | cut -d'"' -f4 )
	if [[ -n $value ]]; then
		sed -i "s/\(Calibration\"  \"\).*/\1$value\"/" /etc/X11/xorg.conf.d/99-calibration.conf
		systemctl start localbrowser
		cp /etc/X11/xorg.conf.d/99-calibration.conf /srv/http/data/system/calibration
	fi
	;;
lcdchardisable )
	if [[ ! -e $dirsystem/lcd ]]; then
		sed -i '/dtparam=i2c_arm=on/ d' $fileconfig
		sed -i '/i2c-bcm2708\|i2c-dev/ d' $filemodule
	fi
	rm -f $dirsystem/lcdchar
	pushRefresh
	;;
lcdcharset )
	val=( ${args[1]} )
	reboot=${args[2]}
	
	cols=${val[0]}
	charmap=${val[1]}
	address=${val[2]}
	chip=${val[3]}
	[[ $cols == 16 ]] && rows=2 || rows=4
	filelcdchar=/srv/http/bash/lcdchar.py

	sed -i -e '/address = /,/i2c_expander/ s/^#//
' -e '/RPLCD.gpio/,/numbering_mode/ s/^#//
' $filelcdchar
	if [[ -n $chip ]]; then
		if ! grep -q 'dtparam=i2c_arm=on' $fileconfig; then
			sed -i '$ a\dtparam=i2c_arm=on' $fileconfig
			echo "\
i2c-bcm2708
i2c-dev" >> $filemodule
			echo "$reboot" > $filereboot
		fi
	else
		if [[ ! -e $dirsystem/lcd ]]; then
			sed -i '/dtparam=i2c_arm=on/ d' $fileconfig
			sed -i '/i2c-bcm2708\|i2c-dev/ d' $filemodule
		fi
	fi
	echo ${args[1]} > $dirsystem/lcdcharset # array to multiline string
	touch $dirsystem/lcdchar
	pushRefresh
	;;
onboardaudio )
	if [[ ${args[1]} == true ]]; then
		onoff=on
		touch $dirsystem/onboard-audio
	else
		onoff=off
		rm -f $dirsystem/onboard-audio
	fi
	sed -i "s/\(dtparam=audio=\).*/\1$onoff/" $fileconfig
	echo "${args[2]}" > $filereboot
	pushRefresh
	;;
regional )
	ntp=${args[1]}
	regom=${args[2]}
	sed -i "s/^\(NTP=\).*/\1$ntp/" /etc/systemd/timesyncd.conf
	sed -i 's/".*"/"'$regdom'"/' /etc/conf.d/wireless-regdom
	iw reg set $regdom
	printf '%s\n' "${args[@]:1}" > $dirsystem/regional
	pushRefresh
	;;
relays )
	enable=${args[1]}
	if [[ $enable == true ]]; then
		touch $dirsystem/relays
	else
		rm -f $dirsystem/relays
	fi
	pushRefresh
	;;
soundprofiledisable )
	soundprofile '18000000 60 1500 1000'
	rm -f $dirsystem/soundprofile
	pushRefresh
	;;
soundprofileget )
	val+=$( sysctl kernel.sched_latency_ns )$'\n'
	val+=$( sysctl vm.swappiness )$'\n'
	if ifconfig | grep -q eth0; then
		val+=$( ifconfig eth0 | awk '/mtu/ {print "mtu = "$NF}' )$'\n'
		val+=$( ifconfig eth0 | awk '/txqueuelen/ {print "txqueuelen = "$4}' )$'\n'
	fi
	echo "${val:0:-1}"
	;;
soundprofileset )
	values=${args[@]:1}
	soundprofile "$values"
	if [[ $values == '18000000 60 1500 1000' || $values == '18000000 60' ]]; then
		rm -f $dirsystem/soundprofile*
	else
		printf '%s\n' "${args[@]:1}" > $dirsystem/soundprofileset
		touch $dirsystem/soundprofile
	fi
	pushRefresh
	;;
statusbootlog )
	if [[ -e $filebootlog ]]; then
		cat $filebootlog
	else
		journalctl -b | sed -n '1,/Startup finished.*kernel/ p' | tee $filebootlog
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
		rm -f $dirsystem/onboard-wlan
		rmmod brcmfmac
	fi
	pushRefresh
	;;
	
esac
