#!/bin/bash

readarray -t args <<< "$1"
profile=${args[0]}
val=${args[1]}

dirsystem=/srv/http/data/system
if [[ -z $profile || $profile == getvalue ]]; then
	profile=$( cat $dirsystem/soundprofile )
else
	echo $profile > $dirsystem/soundprofile
fi
[[ -n $val ]] && echo $val > $dirsystem/soundprofile-custom

code=$( awk '/Revision/ {print $NF}' /proc/cpuinfo )
hwcode=${code: -3:2}
if [[ $hwcode =~ ^(04|08|0d|0e|11)$ ]]; then # not RPi 1
	lat=( 4500000 3500075 1000000 2000000 3700000 1500000 145655 6000000 )
else
	lat=( 1500000 850000 500000 120000 500000 1500000 145655 6000000 )
fi
case $profile in #    mtu  txq  sw lat
	RuneAudio ) val=( 1500 1000 0  ${lat[0]} );;
	ACX )       val=( 1500 4000 0  ${lat[1]} );;
	Orion )     val=( 1000 4000 20 ${lat[2]} );;
	OrionV2 )   val=( 1000 4000 0  ${lat[3]} );;
	Um3ggh1U )  val=( 1500 1000 0  ${lat[4]} );;
	iqaudio )   val=( 1000 4000 0  ${lat[5]} );;
	berrynos )  val=( 1000 4000 60 ${lat[6]} );;
	default )   val=( 1500 1000 60 18000000 );;
	custom )    val=( $( cat $dirsystem/soundprofile-custom ) );;
esac
if [[ ${args[0]} != getvalue ]]; then
	if ifconfig | grep -q eth0; then
		ip link set eth0 mtu ${val[0]}
		ip link set eth0 txqueuelen ${val[1]}
	fi
	sysctl vm.swappiness=${val[2]}
	sysctl kernel.sched_latency_ns=${val[3]}
fi
echo "${val[@]}"
