#!/bin/bash

[[ -n $1 ]] && wlan=$1 || wlan=wlan0

ifconfig $wlan up

listProfile() {
	netctllist=$( netctl list | grep -v eth | sed 's/^\s*\**\s*//' )
	i=0
	if grep -q '^+' <<<"$netctllist"; then # leading '+' = connecting
		(( i++ ))
		(( i == 15 )) && echo -1 && exit
		
		sleep 2
		listProfile
	fi
}
listProfile

if [[ -n $netctllist ]]; then
	readarray -t netctllist_ar <<<"$netctllist"
	# pre-scan saved profile to force display hidden ssid
	for name in "${netctllist_ar[@]}"; do
		grep -q '^Hidden=yes' "/etc/netctl/$name" && iwlist $wlan scan essid "$name" &> /dev/null
	done
fi

connectedssid=$( iwgetid $wlan -r )

iwlistscan=$( iwlist $wlan scan | \
	grep '^\s*Qu\|^\s*En\|^\s*ES\|WPA' | \
	sed 's/^\s*//; s/Quality.*level\| dBm *\|En.*:\|ES.*://g; s/IE: .*\/\(.*\) .* .*/\1/' | \
	tr '\n' ' ' | \
	sed 's/=/\n/g' |
	sort -V )
iwlistscan=${iwlistscan:1} # remove leading \n
readarray -t line <<<"$iwlistscan"
for line in "${line[@]}"; do
	line=( $line )
	dbm=${line[0]}
	encrypt=${line[1]}
	ssid=${line[2]//\"}
	ssid=${ssid/\\x00}
	[[ -z $ssid ]] && continue
	
	[[ ${line[3]:0:3} == WPA ]] && wpa=wpa || wpa=
	file="/etc/netctl/$ssid"
	if [[ -e "$file" ]]; then
		profile=1
		grep -q 'IP=dhcp' "$file" && dhcp=dhcp || dhcp=static
		password=$( grep '^Key' "$file" | tr -d '"' | cut -d'=' -f2 )
	else
		profile=
		dhcp=
		password=
	fi
	if [[ $ssid == $connectedssid ]]; then
		ip=$( ifconfig $wlan | awk '/inet / {print $2}' )
		[[ -n $ip ]] && connected=1
		gateway=$( ip r | grep "^default.*$wlan" | awk '{print $3}' )
		[[ -z $gateway ]] && gateway=$( ip r | grep ^default | head -n1 | cut -d' ' -f3 )
	else
		connected=
		gateway=
		ip=
	fi
	list+=',{"dbm":"'$dbm'","ssid":"'${ssid//\"/\\\"}'","encrypt":"'$encrypt'","wpa":"'$wpa'","profile":"'$profile'","dhcp":"'$dhcp'","connected":"'$connected'","gateway":"'$gateway'","ip":"'$ip'","password":"'$password'"}'
done

echo [${list:1}] # 'remove leading ,
