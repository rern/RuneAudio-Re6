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

/boot/x.sh &> /dev/null

[[ -e $dirsystem/onboard-wlan ]] && ifconfig wlan0 up || rmmod brcmfmac

[[ -e $dirsystem/soundprofile ]] && /srv/http/bash/cmd-soundprofile.sh

/srv/http/bash/mpd-conf.sh # mpd start by this script

sleep 10 # wait for network interfaces
notifyFailed() {
	echo "$1<br><br><gr>Try reboot again.</gr>" > $dirdata/shm/reboot
	curl -s -X POST http://127.0.0.1/pub?id=reload -d 1
}
mountpoints=$( grep /mnt/MPD/NAS /etc/fstab | awk '{print $2}' )
if [[ -n "$mountpoints" ]]; then
	lanip=$( ifconfig | grep -A1 ^eth0 | awk '/inet/ {print $2}' )
	wlanip=$( ifconfig | grep -A1 ^wlan0 | awk '/inet/ {print $2}' )
	if [[ -z $lanip && -z wlanip ]]; then # wait for ip address
		for (( i=0; i <= 20; i++ )); do
			sleep 1
			(( i == 20 )) && notifyFailed 'Network not connected.'
			wlanip=$( ifconfig | grep -A1 ^wlan0 | awk '/inet/ {print $2}' )
			[[ -n $wlanip ]] && break
		done
	fi
	for mountpoint in $mountpoints; do # verify target before mount
		ip=$( grep "$mountpoint" /etc/fstab | cut -d' ' -f1 | sed 's|^//||; s|:*/.*$||' )
		for (( i=0; i <= 20; i++ )); do
			ping -c 1 -w 1 $ip &> /dev/null && break
			
			sleep 1
			(( i == 20 )) && notifyFailed 'NAS IP address cannot be reached.'
		done
		mount $mountpoint
	done
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

for (( i=0; i <= 20; i++ )); do
	wlan0up=$( ip a show wlan0 &> /dev/null )
	[[ -n $wlan0up ]] && break
	
	sleep 1
done
if [[ -e $dirsystem/accesspoint && -n $wlan0up ]]; then
	ifconfig wlan0 $( grep router /etc/dnsmasq.conf | cut -d, -f2 )
	systemctl start dnsmasq hostapd
fi

/srv/http/bash/cmd.sh addonsupdate

if lsmod | grep -q btusb; then
	modprobe btusb
	systemctl start bluetooth
fi

wlans=$( ip a | awk '/wlan.:/ {print $2}' | tr -d ':' )
[[ -z "$wlans" ]] && exit

sleep 15 # wait "power_save" ready for setting
for wlan in $wlans; do
	iw $wlan set power_save off
done 
