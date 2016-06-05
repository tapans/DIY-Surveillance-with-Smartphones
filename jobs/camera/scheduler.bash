#!/bin/bash

if [ -e /opt/surveillanceserver/conf/ipcameras ]; then
    . /opt/surveillanceserver/conf/main

    lat_param=$LATITUDE
    lon_param=$LONGITUDE

    #get sunrise & sunset times and
    read sunrise sunset <<< `/opt/surveillanceserver/helpers/get_sunrise_sunset_times.py $lat_param $lon_param`
    toggle_off_time=`date -d "$sunrise - 30 mins" +'%H:%M'`
    toggle_on_time=`date -d "$sunset + 30 mins" +'%H:%M'`

    #at those time, schedule toggleNightSettings job
    read IP_CAMERA_USERNAMES IP_CAMERA_PASSWORDS IP_CAMERA_HOSTS IP_CAMERA_PORTS <<< `/opt/surveillanceserver/helpers/get_enabled_monitors_data.pl`
    echo "bash /opt/surveillanceserver/jobs/camera/toggleNightSettings.bash on $IP_CAMERA_HOSTS $IP_CAMERA_PORTS $IP_CAMERA_USERNAMES $IP_CAMERA_PASSWORDS " | at -m $toggle_on_time
    echo "bash /opt/surveillanceserver/jobs/camera/toggleNightSettings.bash off $IP_CAMERA_HOSTS $IP_CAMERA_PORTS $IP_CAMERA_USERNAMES $IP_CAMERA_PASSWORDS" | at -m $toggle_off_time
else
    echo "Missing ip cameras configuration file!"
    exit 1
fi
