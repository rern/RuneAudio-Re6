#!/bin/bash

# reset player, tmp files
# set and connect wi-fi if pre-configured
# expand root partition (once)
# enable/disable wlan
# set sound profile if enabled
# set mpd-conf.sh
#   - list sound devices
#   - populate mpd.conf
#   - start mpd, mpdidle
# set autoplay if enabled
# disable wlan power saving
# check addons updates

dirdata=/srv/http/data
dirmpd=$dirdata/mpd
dirsystem=$dirdata/system
playerfile=$dirdata/shm/player

echo '"mpd":true,"airplay":false,"snapclient":false,"spotify":false,"upnp":false' > $playerfile
touch $playerfile-mpd

if [[ -e /boot/wifi ]]; then
	ssid=$( grep '^ESSID' /boot/wifi | cut -d'"' -f2 )
	sed -i -e '/^#\|^$/ d' -e 's/\r//' /boot/wifi
	cp /boot/wifi "$dirsystem/netctl-$ssid"
	mv /boot/wifi "/etc/netctl/$ssid"
	chown http:http "$dirsystem/netctl-$ssid" "/etc/netctl/$ssid"
	netctl start "$ssid"
	systemctl enable netctl-auto@wlan0
fi

[[ -e /boot/x.sh ]] && /boot/x.sh

[[ -e $dirsystem/onboard-wlan ]] && ifconfig wlan0 up || rmmod brcmfmac

[[ -e $dirsystem/soundprofile ]] && /srv/http/bash/cmd-soundprofile.sh

/srv/http/bash/mpd-conf.sh # mpd start by this script

sleep 10 # wait for network interfaces
notifyFailed() {
	echo "$1<br><br><gr>Try reboot again.</gr>" >> $dirdata/shm/reboot
	curl -s -X POST http://127.0.0.1/pub?id=reload -d 1
}
mountpoints=$( grep /mnt/MPD/NAS /etc/fstab | awk '{print $2}' )
if [[ -n "$mountpoints" ]]; then
	lanip=$( ifconfig | grep -A1 ^eth0 | awk '/inet/ {print $2}' )
	wlanip=$( ifconfig | grep -A1 ^wlan0 | awk '/inet/ {print $2}' )
	if [[ -z $lanip && -z wlanip ]]; then # wait for ip address
		for (( i=0; i <= 20; i++ )); do
			wlanip=$( ifconfig | grep -A1 ^wlan0 | awk '/inet/ {print $2}' )
			[[ -n $wlanip ]] && break
			
			sleep 1
			(( i == 20 )) && notifyFailed 'Network not connected.'
		done
	fi
	for mountpoint in $mountpoints; do # verify target before mount
		ip=$( grep "$mountpoint" /etc/fstab | cut -d' ' -f1 | sed 's|^//||; s|:*/.*$||' )
		if [[ $ip != $lanip && $ip != $wlanip ]]; then
			for (( i=0; i <= 20; i++ )); do
				ping -4 -c 1 -w 1 $ip &> /dev/null && break
				
				sleep 1
				(( i == 20 )) && notifyFailed "NAS IP: $ip cannot be reached."
			done
		fi
		mount $mountpoint
	done
fi

if systemctl -q is-enabled hostapd; then
	ifconfig wlan0 $( grep router /etc/dnsmasq.conf | cut -d, -f2 )
	systemctl start dnsmasq hostapd
fi
# after all sources connected
if [[ ! -e $dirmpd/mpd.db ]] || $( mpc stats | awk '/Songs/ {print $NF}' ) -eq 0 ]]; then
	/srv/http/bash/cmd.sh mpcupdate$'\n'true
elif [[ -e $dirsystem/updating ]]; then
	path=$( cat $dirsystem/updating )
	[[ $path == rescan ]] && mpc rescan || mpc update "$path"
elif [[ -e $dirsystem/listing || ! -e $dirmpd/counts ]]; then
	/srv/http/bash/cmd-list.sh &> dev/null &
elif [[ -e $dirsystem/autoplay ]]; then
	mpc play
fi

/srv/http/bash/cmd.sh addonsupdate
