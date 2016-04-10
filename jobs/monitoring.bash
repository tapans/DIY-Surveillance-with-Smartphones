#!/bin/bash

function send_email {
	printf "$1" | mail -a "From: Home Surveillance Server" -s "$2" "$3"
}

if [ -e /opt/surveillanceserver/conf/monitoring ]; then
    . /opt/surveillanceserver/conf/monitoring

    to="$EMAIL_TO"
    curr_cpu_temp=`cat /sys/class/thermal/thermal_zone0/temp`
    curr_disk_usage=`df -H | grep '/dev/loop0' | awk '{ print $5 }' | tr '%' ' '`

    if [ $curr_cpu_temp -gt $CPU_TEMP_THRESHOLD ]
    then
		body="Current CPU Temperature: $curr_cpu_temp C \nThreshold: $CPU_TEMP_THRESHOLD C"
		subject="CPU TEPERATURE HIGH: $curr_cpu_temp C"
		send_email "$body" "$subject" "$to"
    fi

    if [ $curr_disk_usage -gt $DISK_USAGE_THRESHOLD ]
    then
		body="Current disk Usage: $curr_disk_usage % \nThreshold: $DISK_USAGE_THRESHOLD %"
		subject="DISK USAGE HIGH: $curr_disk_usage %"
		send_email "$body" "$subject" "$to"
    fi
else
    echo "missing monitoring configuration file!"
    exit 1
fi