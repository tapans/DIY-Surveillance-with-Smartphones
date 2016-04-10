#!/bin/bash

if [ -e /opt/surveillanceserver/conf/ipcameras ]; then
    . /opt/surveillanceserver/conf/ipcameras
    . /opt/surveillanceserver/conf/main

    lat_param=$LATITUDE
    lng_param=$LONGITUDE

    #get sunrise & sunset times and
    read sunrise sunset \
    <<< `curl -s "http://api.sunrise-sunset.org/json?lat=$lat_param&lng=$lng_param&data=today&formatted=0" \
    | python -c "import json, sys; r=json.load(sys.stdin); print r['results']['sunrise']; print r['results']['sunset']"`
    toggle_off_time=`date -d "$sunrise - 1 hour" +'%H:%M'`
    toggle_on_time=`date -d "$sunset + 1 hour" +'%H:%M'`

    #at those time, schedule toggleNightSettings job
    echo "bash /opt/surveillanceserver/jobs/camera/toggleNightSettings.bash on $IP_CAMERA_HOSTS $IP_CAMERA_PORTS $IP_CAMERA_USERNAMES $IP_CAMERA_PASSWORDS" | at -m $toggle_on_time
    echo "bash /opt/surveillanceserver/jobs/camera/toggleNightSettings.bash off $IP_CAMERA_HOSTS $IP_CAMERA_PORTS $IP_CAMERA_USERNAMES $IP_CAMERA_PASSWORDS" | at -m $toggle_off_time
else
    echo "Missing ip cameras configuration file!"
    exit 1
fi
