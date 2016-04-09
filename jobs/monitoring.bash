#!/bin/bash

if [ -e /opt/surveillanceserver/conf/monitoring ]; then
    . /opt/surveillanceserver/conf/monitoring

    curr_cpu_temp=`cat /sys/class/thermal/thermal_zone0/temp`
    if [ $curr_cpu_temp -gt $CPU_TEMP_THRESHOLD ]
    then
    	printf "Current CPU Temperature: $curr_cpu_temp degrees C \
    			\n Threshold: $CPU_TEMP_THRESHOLD degrees C" | mail -s "CPU TEMPERATURE HIGH" $EMAIL_TO
    fi

else
    echo "Missing monitoring configuration file!"
    exit 1
fi