#!/bin/bash

toggle_night_vision () {
	if [ $1 = "on" ]; then
		curl -u $4:$5 http://$2:$3/settings/night_vision_gain?set=60.00
	fi
	curl -u $4:$5 http://$2:$3/settings/night_vision?set=$1
}

if [ $# -eq 3 ] || [ $# -eq 5 ]; then
	#create bash arrays for each param
	hosts=(`echo $2 | tr ":" " "`)
	ports=(`echo $3 | tr ":" " "`)
	usernames=(`echo $4 | tr ":" " "`)
	passwords=(`echo $5 | tr ":" " "`)
	
	num_hosts=${#hosts[@]}	
	
	for (( i=0; i<${num_hosts}; i++ ));
	do
		toggle_night_vision $1 ${hosts[$i]} ${ports[$i]} ${usernames[$i]} ${passwords[$i]}
	done
else
	echo "Usage: on|off ip_camera_host ip_camera_port"
	echo "Usage: on|off ip_camera_host ip_camera_port username password"
	echo "Usage: on|off ip1:ip2:ipn port1:port2:portn"
	echo "Usage: on|off ip1:ip2:ipn port1:port2:portn user1:user2:usern pass1:pass2:passn"
	exit 1
fi