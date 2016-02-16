#!/bin/bash

PATH=/bin:/usr/bin:/usr/local/bin

##1. Read & source config file after sanitizing, and do an update
echo -e "\e[33m Checking config file...\e[0m" >&2
configfile='./conf/config'

# check if config file contains bad input
if egrep -q	 -v '^#|^[^ ]*=[^;]*' $configfile; then
	echo -e "\e[31m Bad configurations. Only name=value pairs allowed in config file! \e[0m";
	exit 1;
fi
echo -e "\e[32m Config file good.\e[0m"
. $configfile

##2. Install Zoneminder for Debian Jesse
echo -e "\e[33m Getting Jessie backports, install Zoneminder and dependencies \e[0m"
echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list
apt-get update
apt-get install -y php5 mysql-server php-pear php5-mysql
apt-get upgrade
apt-get dist-upgrade
apt-get install -y zoneminder
apt-get install -y libvlc-dev libvlccore-dev vlc

###Steps 3 and 4 adopted from Zoneminder Wiki page:
###https://wiki.zoneminder.com/Debian_8.1_64-bit_with_Zoneminder_1.28.1_the_Easy_Way
##3. Create and configure Zoneminder database in MySQL
echo -e "\e[33m Creating Zoneminder database in mysql \e[0m"
cd ~
cat << EOMYSQLCONF > .my.cnf 
[client]
user=$dbuser
password=$dbpass
EOMYSQLCONF
mysql < /usr/share/zoneminder/db/zm_create.sql 
mysql -e "grant select,insert,update,delete,create on zm.* to 'zmuser'@localhost identified by 'zmpass';"
rm .my.cnf

##4. Configure and Start Zoneminder
#Set permissions of /etc/zm/zm.conf to root:www-data 740
chmod 740 /etc/zm/zm.conf
chown root:www-data /etc/zm/zm.conf
# Enable Zoneminder service to start at boot
systemctl enable zoneminder.service
# Add www-data to the sudo group (to enable use of local video devices)
adduser www-data video
service zoneminder start
# Enable CGI and Zoneminder configuration in Apache.
a2enmod cgi
a2enconf zoneminder
service apache2 restart
# Optional: Install Cambozola (needed if you use Internet Explorer)
cd /usr/src && wget http://www.andywilcock.com/code/cambozola/cambozola-latest.tar.gz
tar -xzvf cambozola-latest.tar.gz
cp cambozola*/dist/cambozola.jar /usr/share/zoneminder

##5. TODO: Configure Email, Night Vision cron jobs, back ups, and monitoring jobs