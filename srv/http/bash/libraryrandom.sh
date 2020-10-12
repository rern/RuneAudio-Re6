#!/bin/bash

while :; do
	mpc idle player

	counts=$( mpc | awk '/\[playing\]/ {print $2}' | tr -d '#' )
	pos=${counts/\/*}
	total=${counts/*\/}

	if (( $(( total - pos )) < 2 )); then
		length=$( mpc listall | wc -l )
		mpc add "$( mpc listall | sed "$(( 1 + RANDOM % $length ))q;d" )"
	fi

done
