#!/bin/bash

dirdata=/srv/http/data
diraddons=$dirdata/addons
dirsystem=$dirdata/system
dirtmp=$dirdata/shm

systemctl stop mpd
rm -f $dirsystem/{updating,listing,wav}

# lcd
sed -i 's/ console=ttyAMA0.*ProFont6x11//' /boot/cmdline.txt
sed -i '/i2c-bcm2708\|i2c-dev/ d' /etc/modules-load.d/raspberrypi.conf
sed -i 's/fb1/fb0/' /usr/share/X11/xorg.conf.d/99-fbturbo.conf 2> /dev/null

# config.txt
code=$( awk '/Revision/ {print $NF}' /proc/cpuinfo )
hwcode=${code: -3:2}
if (( $# == 0 )); then
	case $hwcode in
		09 | 0c )         rpi=0;;
		00 | 01 |02 |03 ) rpi=1
		11 )              rpi=4;;
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
# addons - new/backup
if [[ -n $1 ]]; then # from createrune.sh
	version=$1
else
	mv $diraddons $dirtmp
	rm -rf $dirdata
fi
# data directories
mkdir -p $dirdata/{addons,bookmarks,embedded,lyrics,mpd,playlists,system,tmp,webradios,webradiosimg} /mnt/MPD/{NAS,SD,USB}
ln -sf /dev/shm $dirdata
# addons - new/restore
if [[ -n $version ]]; then # from createrune.sh
	echo $version > $dirsystem/version
	wget -qO - https://github.com/rern/RuneAudio_Addons/raw/master/addons-list.json \
		| jq -r .rr$version.version \
		> $diraddons/rr$version
else
	mv $dirtmp/addons $dirdata
fi
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
	"progressbar": false,
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
echo 'bcm2835 Headphones' > $dirsystem/audio-aplayname
echo 'On-board - Headphone' > $dirsystem/audio-output
echo RuneAudio > $dirsystem/hostname
touch $dirsystem/{onboard-audio,onboard-wlan}
[[ $rpi == 0 || $rpi == 1 ]] && touch $dirsystem/localbrowser
rm -f $dirsystem/{lcd,lcdchar,relays,soundprofile}
hostnamectl set-hostname runeaudio
sed -i 's/#NTP=.*/NTP=pool.ntp.org/' /etc/systemd/timesyncd.conf
sed -i 's/".*"/"00"/' /etc/conf.d/wireless-regdom
timedatectl set-timezone UTC

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
# mpd
sed -i -e '/^auto_update\|^audio_buffer_size\| #custom$/ d
' -e '/quality/,/}/ d
' -e '/soxr/ a\
	quality        "very high"\
}
' /etc/mpd.conf

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

[[ -n $version ]] && exit

systemctl start mpd

curl -s -X POST http://127.0.0.1/pub?id=restore -d '{"restore":"reload"}' &> /dev/null
