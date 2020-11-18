#!/bin/bash

dirsystem=/srv/http/data/system

# convert each line to each args
readarray -t args <<< "$1"

pushRefresh() {
	sleep 1
	curl -s -X POST http://127.0.0.1/pub?id=refresh -d '{ "page": "network" }'
}

case ${args[0]} in

btdisconnect )
	bluetoothctl disconnect ${args[1]}
	sleep 2
	pushRefresh
	;;
btpair )
	mac=${args[1]}
	bluetoothctl trust $mac
	bluetoothctl pair $mac
	bluetoothctl connect $mac
	[[ $? == 0 ]] && pushRefresh || echo -1
	;;
btremove )
	mac=${args[1]}
	bluetoothctl disconnect $mac
	bluetoothctl remove $mac
	sleep 2
	pushRefresh
	;;
btset )
	bluetoothctl system-alias $( cat $dirsystem/hostname )
	[[ ! -e $dirsystem/btdiscoverno ]] && bluetoothctl discoverable yes
	bluetoothctl discoverable-timeout 0
	bluetoothctl pairable yes
	;;
connect )
	wlan=${args[1]}
	ssid=${args[2]}
	dhcp=${args[3]}
	if [[ -n $dhcp ]]; then
		wpa=${args[4]}
		password=${args[5]}
		hidden=${args[6]}
		ip=${args[7]}
		gw=${args[8]}
		
		profile="\
Interface=$wlan
Connection=wireless
ESSID=\"$ssid\"
IP=$dhcp
"
		if [[ -n $password ]]; then
			profile+="\
Security=$wpa
Key=\"$password\"
"
		else
			profile+="\
Security=none
"
		fi
		[[ -n $hidden ]] && profile+="\
Hidden=yes
"
		[[ $dhcp == static ]] && profile+="\
Address=$ip/24
Gateway=$gw
"
		echo "$profile" > "/etc/netctl/$ssid"
	fi
	
	ifconfig $wlan down
	if netctl switch-to "$ssid"; then
		systemctl enable netctl-auto@$wlan
	else
		echo -1
		rm -f "/etc/netctl/$ssid"
	fi
	ifconfig $wlan up
	pushRefresh
	;;
disconnect )
	wlan=${args[1]}
	ssid=${args[2]}
	netctl stop-all
	killall wpa_supplicant
	ifconfig $wlan up
	if [[ -n $ssid ]]; then
		systemctl disable netctl-auto@$wlan
		rm -f "/etc/netctl/$ssid" "/srv/http/data/system/netctl-$ssid"
	fi
	pushRefresh
	;;
editlan )
	ip=${args[1]}
	gw=${args[2]}
	eth0="\
[Match]
Name=eth0
[Network]
DNSSEC=no
"
	if [[ -z $ip ]];then
		eth0+="\
DHCP=yes
"
		rm -f /srv/http/data/system/eth0.network
	else
		arp -n | grep -q ^$ip && echo -1 && exit
		
		eth0+="\
Address=$ip/24
Gateway=$gw
"
		echo "$eth0" > /srv/http/data/system/eth0.network
	fi
	echo "$eth0" > /etc/systemd/network/eth0.network
	systemctl restart systemd-networkd
	pushRefresh
	;;
editwifidhcp )
	ssid=${args[1]}
	file="/srv/http/data/system/netctl-$ssid"
	netctl stop "$ssid"
	sed -i -e '/^Address\|^Gateway/ d
' -e 's/^IP.*/IP=dhcp/
' "$file"
	cp "$file" "/etc/netctl/$ssid"
	netctl start "$ssid"
	pushRefresh
	;;
ifconfig )
	lines=$( ifconfig \
		| sed -n '/^eth\|^wlan/,/ether/ p' \
		| grep -v inet6 \
		| sed 's/^\(.*\): .*/\1/; s/^ *inet \(.*\)   *net.*/\1/; s/^ *ether \(.*\)   *txq.*/\1=/' \
		| tr '\n' ' ' \
		| sed 's/= /\n/g' )
	echo "$lines"
	;;
ipused )
	arp -n | grep -q ^${args[1]} && echo 1 || echo 0
	;;
statusnetctl )
	lists=$( netctl list )
	[[ -z $lists ]] && echo '(none)' && exit
	
	readarray -t lists <<< "$lists"
	for list in "${lists[@]}"; do
		name=$( sed 's/^-*\** *//' <<< $list )
		profiles+="<hr>$name<hr>$( cat /etc/netctl/$name | sed -e '/^#.*/ d' -e 's/Key=.*/Key="*********"/' )"
	done
	echo "$profiles"
	;;
statuswifi )
	value=$( grep '^Address\|^Gateway\|^IP\|^Key\|^Security' "/etc/netctl/${args[1]}" \
				| tr -d '"' \
				| sed 's/^/"/ ;s/=/":"/; s/$/",/' )
	echo {${value:0:-1}}
	;;
	
esac
