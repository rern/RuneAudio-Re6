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

data='
	  "cpuload"         : "'$( cat /proc/loadavg | cut -d' ' -f1-3 | sed 's/ /, /g' )'"
	, "cputemp"         : '$( /opt/vc/bin/vcgencmd measure_temp | sed 's/[^0-9.]//g' )'
	, "startup"         : "'$( systemd-analyze | head -1 | cut -d' ' -f4,7 )'"
	, "time"            : "'$( date +'%T %F' )'"
	, "timezone"        : "'$( timedatectl | awk '/zone:/ {print $3}' | sed 's|/| · |' )'"
	, "uptime"          : "'$( uptime -p | tr -d 's,' | sed 's/up //; s/ day/d/; s/ hour/h/; s/ minute/m/' )'"
	, "uptimesince"     : "'$( uptime -s | cut -d: -f1-2 )'"
	, "undervoltage"    : '$undervoltage'
	, "undervdetected"  : '$undervdetected

# for interval refresh
(( $# > 0 )) && echo {$data} && exit

hwcode=$( awk '/Revision/ {print $NF}' <<< "$( cat /proc/cpuinfo )" )
case ${hwcode: -4:1} in
	0 ) soc=BCM2835;;
	1 ) soc=BCM2836;;
	2 ) [[ ${hwcode: -3:2} > 08 ]] && soc=BCM2837B0 || soc=BCM2837;;
	3 ) soc=BCM2711;;
esac
case ${hwcode: -6:1} in
	9 ) socram+='512KB';;
	a ) socram+='1GB';;
	b ) socram+='2GB';;
	c ) socram+='4GB';;
esac

lines=$( /srv/http/bash/networks.sh ifconfig )
readarray -t lines <<<"$lines"
for line in "${lines[@]}"; do
    items=( $line )
    iplist+=",${items[0]} ${items[1]} ${items[2]}"
done

dirsystem=/srv/http/data/system
version=$( cat $dirsystem/version )
snaplatency=$( grep OPTS= /etc/default/snapclient | sed 's/.*latency=\(.*\)"/\1/' )
lcdcharset=$( grep '^address\|^chip\|^cols' /srv/http/bash/lcdchar.py | cut -d' ' -f3 | tr -d "'" )
[[ -z $snaplatency ]] && snaplatency=0
if grep -q 'dtparam=i2c_arm=on' /boot/config.txt; then
	dev=$( ls /dev/i2c* 2> /dev/null | tail -c 2 )
	[[ -n $dev ]] && lcdcharaddr=$( i2cdetect -y $dev \
									| grep -v '^\s' \
									| cut -d' ' -f2- \
									| tr -d ' \-' \
									| grep -v UU \
									| grep . \
									| sort -u )
fi

data+='
	, "audioaplayname"  : "'$( cat $dirsystem/audio-aplayname 2> /dev/null )'"
	, "audiooutput"     : "'$( cat $dirsystem/audio-output )'"
	, "hostname"        : "'$( cat $dirsystem/hostname )'"
	, "ip"              : "'${iplist:1}'"
	, "kernel"          : "'$( uname -r )'"
	, "lcd"             : '$( grep -q dtoverlay=tft35a /boot/config.txt && echo true || echo false )'
	, "lcdchar"         : '$( [[ -e $dirsystem/lcdchar ]] && echo true || echo false )'
	, "lcdcharset"      : '$( [[ -e $dirsystem/lcdcharset ]] && echo true || echo false )'
	, "lcdcharaddr"     : "'$lcdcharaddr'"
	, "lcdcharval"      : "'$( cat /srv/http/data/system/lcdcharset )'"
	, "mpd"             : "'$( pacman -Q mpd 2> /dev/null |  cut -d' ' -f2 )'"
	, "mpdstats"        : "'$( jq '.song, .album, .artist' /srv/http/data/mpd/counts 2> /dev/null )'"
	, "ntp"             : "'$( grep '^NTP' /etc/systemd/timesyncd.conf | cut -d= -f2 )'"
	, "onboardaudio"    : '$( grep -q 'dtparam=audio=on' /boot/config.txt && echo true || echo false )'
	, "reboot"          : "'$( cat /srv/http/data/shm/reboot 2> /dev/null )'"
	, "regdom"          : "'$( cat /etc/conf.d/wireless-regdom | cut -d'"' -f2 )'"
	, "relays"          : '$( [[ -e $dirsystem/relays ]] && echo true || echo false )'
	, "rpi01"           : '$( [[ $soc == BCM2835 ]] && echo true || echo false )'
	, "rpimodel"        : "'$( cat /proc/device-tree/model )'"
	, "soc"             : "'$soc'"
	, "soccpu"          : "'$( lscpu | awk '/Model name/ {print $NF}' )'"
	, "socram"          : "'$socram'"
	, "socspeed"        : "'$( lscpu | awk '/CPU max/ {print $NF}' | cut -d. -f1 )'"
	, "soundprofile"    : '$( [[ -e $dirsystem/soundprofile ]] && echo true || echo false )'
	, "soundprofileset" : '$( [[ -e $dirsystem/soundprofileset ]] && echo true || echo false )'
	, "soundlatency"    : '$( sysctl kernel.sched_latency_ns | awk '{print $NF}' )'
	, "soundswappiness" : '$( sysctl vm.swappiness | awk '{print $NF}' )'
	, "sources"         : '$( /srv/http/bash/sources-data.sh )'
	, "version"         : "'$version'"
	, "versionui"       : '$( cat /srv/http/data/addons/rr$version 2> /dev/null || echo 0 )
if ifconfig | grep -q ^eth0; then
	data+='
	, "soundmtu"        : '$( ifconfig eth0 | awk '/mtu/ {print $NF}' )'
	, "soundtxqueuelen" : '$( ifconfig eth0 | awk '/txqueuelen/ {print $4}' )
fi
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
