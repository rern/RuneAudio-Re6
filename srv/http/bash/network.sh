#!/bin/bash

dirsystem=/srv/http/data/system

# convert each line to each args
readarray -t args <<< "$1"

pushRefresh() {
	sleep 1
	curl -s -X POST http://127.0.0.1/pub?id=refresh -d '{ "page": "network" }'
}

case ${args[0]} in

accesspoint )
	if [[ ${args[1]} == true ]]; then
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
	" -e "s/^\(.*option:dns-server,\).*/\1$router
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
btdisconnect )
	bluetoothctl disconnect ${args[1]}
	[[ $? == 0 ]] && pushRefresh
	;;
btpair )
	mac=${args[1]}
	bluetoothctl disconnect
	bluetoothctl trust $mac
	bluetoothctl pair $mac
	bluetoothctl connect $mac
	[[ $? == 0 ]] && pushRefresh || echo -1
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
		echo "$profile" | tee "/srv/http/data/system/netctl-$ssid" > "/etc/netctl/$ssid"
	fi
	
	ifconfig $wlan down
	if netctl switch-to "$ssid"; then
		systemctl enable netctl-auto@$wlan
	else
		echo -1
		rm "/srv/http/data/system/netctl-$ssid" "/etc/netctl/$ssid"
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
		rm "/etc/netctl/$ssid" "/srv/http/data/system/netctl-$ssid"
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
		rm /srv/http/data/system/eth0.network
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
statusifconfig )
	ifconfig
	if systemctl -q is-active bluetooth; then
		echo '<hr>'
		bluetoothctl show | sed 's/^\(Controller.*\)/bluetooth: \1/'
	fi
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
