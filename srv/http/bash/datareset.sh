#!/bin/bash

# data - settings directories
dirdata=/srv/http/data
diraddons=$dirdata/addons
dirsystem=$dirdata/system
dirtmp=$dirdata/shm

systemctl stop mpd
rm -f $dirsystem/{updating,listing,wav}

# config.txt
code=$( awk '/Revision/ {print $NF}' /proc/cpuinfo )
hwcode=${code: -3:2}
if (( $# == 0 )); then
	case $hwcode in
		09 | 0c ) rpi=0;;
		11 )      rpi=4;;
	esac
	config="\
over_voltage=2
hdmi_drive=2
force_turbo=1
gpu_mem=32
initramfs initramfs-linux.img followkernel
max_usb_current=1
disable_splash=1
disable_overscan=1
dtparam=audio=on
"
	[[ $rpi != 0 ]] && config=$( sed '/over_voltage\|hdmi_drive/ d' <<<"$config" )
	[[ $rpi == 4 ]] && config=$( sed '/force_turbo/ d' <<<"$config" )
	
	echo -n "$config" > /boot/config.txt
fi

if [[ -n $1 ]]; then
	version=$1
	versionui=$( wget -qO - https://github.com/rern/RuneAudio_Addons/raw/master/addons-list.json \
					| jq -r .rr$version.version )
else
	version=$( cat $dirsystem/version )
	versionui=$( cat $diraddons/rr$version )
	
fi
rm -rf $dirdata
mkdir -p $dirdata/{addons,bookmarks,embedded,lyrics,mpd,playlists,system,tmp,webradios,webradiosimg} /mnt/MPD/{NAS,SD,USB}
ln -sf /dev/shm $dirdata

echo $version > $dirsystem/version
echo $versionui > $diraddons/rr$version
mv $dirtmp/addons $dirdata 2> /dev/null

# display
echo '{
	"album": true,
	"albumbyartist": false,
	"albumartist": true,
	"artist": true,
	"composer": true,
	"date": true,
	"genre": true,
	"nas": true,
	"sd": true,
	"usb": true,
	"webradio": true,
	"backonleft": false,
	"count": true,
	"fixedcover": true,
	"hidecover": false,
	"label": true,
	"playbackswitch": true,
	"plclear": true,
	"tapaddplay": false,
	"tapreplaceplay": false,
	"bars": true,
	"barsalways": false,
	"buttons": true,
	"cover": true,
	"coversmall": false,
	"radioelapsed": false,
	"time": true,
	"volume": true
}' > $dirsystem/display
echo '[
	"SD",
	"USB",
	"NAS",
	"WebRadio",
	"Album",
	"Artist",
	"AlbumArtist",
	"Composer",
	"Genre",
	"Date"
]' > $dirsystem/order
echo '"mpd":true,"airplay":false,"snapclient":false,"spotify":false,"upnp":false' > $dirdata/shm/player
# system
hostnamectl set-hostname runeaudio
sed -i 's/#NTP=.*/NTP=pool.ntp.org/' /etc/systemd/timesyncd.conf
timedatectl set-timezone UTC
# on-board audio
echo 'bcm2835 Headphones' > $dirsystem/audio-aplayname
echo 'On-board - Headphone' > $dirsystem/audio-output
touch $dirsystem/{localbrowser,onboard-audio,onboard-wlan}
# nowireless
[[ $hwcode =~ ^(00|01|02|03|04|09)$ ]] && rm $dirsystem/onboard-wlan
[[ $hwcode =~ ^(00|01|02|03|09|0c)$ ]] && rm $dirsystem/localbrowser
echo RuneAudio | tee $dirsystem/{hostname,soundprofile} > /dev/null
echo '$2a$12$rNJSBU0FOJM/jP98tA.J7uzFWAnpbXFYx5q1pmNhPnXnUu3L1Zz6W' > $dirsystem/password
# gpio
echo '{
  "name": {
    "11": "DAC",
    "13": "PreAmp",
    "15": "Amp",
    "16": "Subwoofer"
  },
  "on": {
    "on1": 11,
    "ond1": 2,
    "on2": 13,
    "ond2": 2,
    "on3": 15,
    "ond3": 2,
    "on4": 16
  },
  "off": {
    "off1": 16,
    "offd1": 2,
    "off2": 15,
    "offd2": 2,
    "off3": 13,
    "offd3": 2,
    "off4": 11
  },
  "timer": 5
}' > $dirsystem/gpio.json
usermod -a -G root http # add user http to group root to allow /dev/gpiomem access

# webradio default
wget -qO - https://github.com/rern/RuneOS/raw/master/radioparadise.tar.xz | bsdtar xvf - -C /

# set permissions and ownership
chown -R http:http /srv/http
chown -R mpd:audio $dirdata/mpd /mnt/MPD
chmod 755 /srv/http/* /srv/http/bash/* /srv/http/settings/*
chmod 777 /srv/http/data/tmp

# symlink /mnt for coverart files
ln -sf /mnt /srv/http/

[[ -n $1 ]] && exit

systemctl start mpd

curl -s -X POST http://127.0.0.1/pub?id=restore -d '{"restore":"reload"}' &> /dev/null
