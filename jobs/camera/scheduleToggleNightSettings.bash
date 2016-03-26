#!/bin/bash

if [ -e /opt/ipcameras/ipcameras.conf ]; then
	. /opt/ipcameras/ipcameras.conf
	
	#get time from api call
	#at that time, run toggleNightSettings
else
	echo "Missing ip cameras configuration file!"
	exit 1