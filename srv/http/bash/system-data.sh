#!/bin/bash

# vcgencmd get_throttled > 0xDDDDD (decimal)
#  1st D > binary BBBB - occured
#    1st B = Soft temperature limit
#    2nd B = Throttling
#    3rd B = Arm frequency capping
#    4th B = Under-voltage
#  5th D > binary BBBB - current
#    1st B = Soft temperature limit active
#    2nd B = Currently throttled
#    3rd B = Arm frequency capped
#    4th B = Under-voltage detected
throttle=$( /opt/vc/bin/vcgencmd get_throttled )
if [[ $throttle != 0x0 ]]; then
	D2B=( {0..1}{0..1}{0..1}{0..1} )
	undervoltage=${throttle: -1}
	[[ $( echo ${D2B[$undervoltage]} | cut -c4 ) == 1 ]] && undervoltage=true || undervoltage=false
	undervdetected=${throttle: -5:1}
	[[ $( echo ${D2B[$undervdetected]} | cut -c4 ) == 1 ]] && undervdetected=true || undervdetected=false
fi

bullet='<gr> &bull; </gr>'
cpuload=$( cat /proc/loadavg | cut -d' ' -f1-3 | sed 's/ /\&emsp;/g' )
cputemp=$( printf "%.0f\n" $( /opt/vc/bin/vcgencmd measure_temp | cut -d= -f2 | cut -d\' -f1 ) )
date=( $( date +'%T %F' ) )
startup=$( systemd-analyze | head -1 | cut -d' ' -f4- \
			| sed 's/ = .*//; s|(|<gr class=\\"wide\\">(|g; s|)|)</gr>|g' )
timezone=$( timedatectl | awk '/zone:/ {print $3}' )
time="${date[0]}$bullet${date[1]}&emsp;<grw>${timezone//\// &middot; }</grw>"
uptime=$( uptime -p | tr -d 's,' | sed 's/up //; s/ day/d/; s/ hour/h/; s/ minute/m/' )
uptimesince=$( uptime -s | cut -d: -f1-2 )
uptime+="<span class='wide'>&emsp;<gr>since ${uptimesince/ / &bull; }</gr></span>"

data='
	  "cpuload"         : "'$cpuload'"
	, "cputemp"         : '$cputemp'
	, "startup"         : "'$startup'"
	, "time"            : "'$time'"
	, "uptime"          : "'$uptime'"
	, "undervoltage"    : '$undervoltage'
	, "undervdetected"  : '$undervdetected

# for interval refresh
(( $# > 0 )) && echo {$data} && exit

cpuinfo=$( cat /proc/cpuinfo )
lscpu=$( lscpu )
soc=$( awk '/Hardware/ {print $NF}' <<< "$cpuinfo" )
cpucores=$( awk '/CPU\(s\):/ {print $NF}' <<< "$lscpu" )
cpuname=$( awk '/Model name/ {print $NF}' <<< "$lscpu" )
cpuspeed=$( awk '/CPU max/ {print $NF}' <<< "$lscpu" | cut -d. -f1 )
(( $cpucores > 1 )) && cores=" $cpucores"
soc="<span class='wide'>$soc$bullet</span>$cores $cpuname @ "
(( $cpuspeed < 1000 )) && soc+="${cpuspeed}MHz" || soc+="$( awk "BEGIN { printf \"%.1f\n\", $cpuspeed / 1000 }" )GHz"
soc+=$bullet
hwcode=$( awk '/Revision/ {print $NF}' <<< "$cpuinfo" )
case ${hwcode: -6:1} in
	9 ) soc+='512KB';;
	a ) soc+='1GB';;
	b ) soc+='2GB';;
	c ) soc+='4GB';;
esac

lines=$( /srv/http/bash/network.sh ifconfig )
readarray -t lines <<<"$lines"
for line in "${lines[@]}"; do
    items=( $line )
    iplist+=",${items[0]} ${items[1]} ${items[2]}"
done

dirsystem=/srv/http/data/system
version=$( cat $dirsystem/version )
snaplatency=$( grep OPTS= /etc/default/snapclient | sed 's/.*latency=\(.*\)"/\1/' )
[[ -z $snaplatency ]] && snaplatency=0
if grep -q 'dtparam=i2c_arm=on' /boot/config.txt; then
	lcdcharaddr=$( i2cdetect -y $( ls /dev/i2c* | tail -c 2 ) \
					| grep -v '^\s' \
					| cut -d' ' -f2- \
					| tr -d ' \-' \
					| grep . \
					| sort -u )
else
	lcdcharaddr='27 3F'
fi

data+='
	, "audioaplayname"  : "'$( cat $dirsystem/audio-aplayname 2> /dev/null )'"
	, "audiooutput"     : "'$( cat $dirsystem/audio-output )'"
	, "hardware"        : "'$( awk '/Model/ {$1=$2=""; print}' <<< "$cpuinfo" )'"
	, "hostname"        : "'$( cat $dirsystem/hostname )'"
	, "ip"              : "'${iplist:1}'"
	, "kernel"          : "'$( uname -r )'"
	, "lcd"             : '$( grep -q dtoverlay=tft35a /boot/config.txt && echo true || echo false )'
	, "lcdchar"         : '$( [[ -e $dirsystem/lcdchar ]] && echo true || echo false )'
	, "lcdcharset"      : '$( [[ -e $dirsystem/lcdcharset ]] && echo true || echo false )'
	, "lcdcharaddr"     : "'$lcdcharaddr'"
	, "lcdcharval"      : "'$( grep '^cols\|^charmap\|^address\|^chip' /srv/http/bash/lcdchar.py | cut -d' ' -f3 | tr -d "'" )'"
	, "mpd"             : "'$( pacman -Q mpd 2> /dev/null |  cut -d' ' -f2 )'"
	, "mpdstats"        : "'$( jq '.song, .album, .artist' /srv/http/data/mpd/counts 2> /dev/null )'"
	, "ntp"             : "'$( grep '^NTP' /etc/systemd/timesyncd.conf | cut -d= -f2 )'"
	, "onboardaudio"    : '$( grep -q 'dtparam=audio=on' /boot/config.txt && echo true || echo false )'
	, "reboot"          : "'$( cat /srv/http/data/shm/reboot 2> /dev/null )'"
	, "regdom"          : "'$( cat /etc/conf.d/wireless-regdom | cut -d'"' -f2 )'"
	, "relays"          : '$( [[ -e $dirsystem/relays ]] && echo true || echo false )'
	, "rpi01"           : "'$( [[ $soc == BCM2835 || $soc == BCM2836 ]] && rpi01=true || rpi01=false )'"
	, "soc"             : "'$soc'"
	, "soundprofile"    : '$( [[ -e $dirsystem/soundprofile ]] && echo true || echo false )'
	, "soundprofileset" : '$( [[ -e $dirsystem/soundprofileset ]] && echo true || echo false )'
	, "soundprofileval" : "'$( cat $dirsystem/soundprofileset 2> /dev/null )'"
	, "sources"         : '$( /srv/http/bash/sources-data.sh )'
	, "timezone"        : "'$timezone'"
	, "version"         : "'$version'"
	, "versionui"       : '$( cat /srv/http/data/addons/rr$version 2> /dev/null || echo 0 )
if [[ -e /usr/bin/bluetoothctl  ]]; then
	bluetooth=$( grep -q dtparam=krnbt=on /boot/config.txt && echo true || echo false )
	bluetoothon=$( systemctl -q is-active bluetooth && echo true || echo false )
	if [[ $bluetoothon == true ]]; then
		btdiscoverable=$( bluetoothctl show | grep -q 'Discoverable: yes' && echo true || echo false )
	else
		btdiscoverable=false
	fi
	data+='
	, "bluetooth"       : '$bluetooth'
	, "bluetoothon"     : '$bluetoothon'
	, "btdiscoverable"  : '$btdiscoverable
fi
[[ ${hwcode: -3:2} =~ ^(08|0c|0d|0e|11)$ ]] && data+='
	, "wlan"            : '$( lsmod | grep -q '^brcmfmac ' && echo true || echo false )

echo {$data}
