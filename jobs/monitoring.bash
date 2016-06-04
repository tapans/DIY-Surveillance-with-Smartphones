#!/bin/bash

function send_email {
	printf "$1" | mail -a "From: Home Surveillance Server" -s "$2" "$3"
}

if [ -e /opt/surveillanceserver/conf/monitoring ]; then
    . /opt/surveillanceserver/conf/monitoring
    . /opt/surveillanceserver/conf/ipcameras

    to="$EMAIL_TO"
    curr_cpu_temp=`cat /sys/class/thermal/thermal_zone0/temp`
    curr_disk_usage=`df -H | grep '/dev/loop0' | awk '{ print $5 }' | tr '%' ' '`
    curr_batt_level=`cat /sys/class/power_supply/battery/capacity`

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

    if [ $curr_batt_level -lt $BATTERY_LEVEL_THRESHOLD ]
    then
        body="Current batter level: $curr_batt_level % \nMinimum Threshold: $BATTERY_LEVEL_THRESHOLD %"
        subject="BATTERY LEVEL LOW: $curr_batt_level %"
        send_email "$body" "$subject" "$to"
    fi

    hosts=(`echo $IP_CAMERA_HOSTS | tr ":" " "`)
    ports=(`echo $IP_CAMERA_PORTS | tr ":" " "`)
    usernames=(`echo $IP_CAMERA_USERNAMES | tr ":" " "`)
    passwords=(`echo $IP_CAMERA_PASSWORDS | tr ":" " "`)

    num_hosts=${#hosts[@]}

    for (( i=0; i<${num_hosts}; i++ ));
    do
        statusCode=$(curl -s -u ${usernames[$i]}:${passwords[$i]} http://${hosts[$i]}:${ports[$i]} -I | head -1 | awk '{ print $2 }')
        if [ -z $statusCode ] || [ $statusCode -ne "200" ]
        then
            body="Got non 200 response code of $statusCode from http://${hosts[$i]}:${ports[$i]}"
            subject="Got non 200 response from ${hosts[$i]}"
            send_email "$body" "$subject" "$to"
        fi
    done
else
    echo "missing monitoring configuration file!"
    exit 1
fi