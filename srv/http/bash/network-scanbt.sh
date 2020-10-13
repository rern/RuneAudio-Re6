#!/bin/bash

if [[ $1 == scan ]]; then
	timeout 10 bluetoothctl scan on
	killall bluetoothctl # failed: bluetoothctl scan off
fi

lines=$( bluetoothctl devices | cut -d' ' -f2- )
[[ -z $lines ]] && echo [] && exit

readarray -t lines <<<"$lines"
for line in "${lines[@]}"; do
	name=${line#* }
	dash=${name//[^-]}
	(( ${#dash} == 5 )) && continue
	mac=${line/ *}
	connected=$( bluetoothctl info $mac | grep -q 'Connected: yes' && echo true || echo false )
	data+='{"name":"'${name//\"/\\\"}'","mac":"'$mac'","connected":'$connected'}\n'
done
data=$( echo -e "$data" | sort -f | awk NF | tr '\n' ',' )

echo [${data:0:-1}]
