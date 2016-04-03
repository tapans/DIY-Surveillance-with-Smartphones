#!/bin/bash

##1. Read & source config file after sanitizing, update, and setup global configs
echo -e "\e[33m Checking config file...\e[0m" >&2
mainConfigs='./conf/main'
cameraConfigs="./conf/ipcameras'"

# check if config file contains bad input
if egrep -q -v '^#|^[^ ]*=[^;]*' $mainConfigs && egrep -v '^#|^[^ ]*=[^;]*' $cameraConfigs ; then
	echo -e "\e[31m Bad configurations. Only name=value pairs allowed in config files! \e[0m";
	exit 1;
fi

#copy configs and job scripts to /opt/surveillanceserver location
mkdir -p /opt/surveillanceserver/ipcameras/jobs
cp conf/main /opt/surveillanceserver/main.conf
cp conf/ipcameras /opt/surveillanceserver/ipcameras/ipcameras.conf
cp jobs/camera/* /opt/surveillanceserver/ipcameras/jobs/

#make variables from main.conf available in current environment
. $mainConfigs

echo -e "\e[32m Config files good. \e[0m"

#setup timezone
echo $TIMEZONE > /etc/timezone
export TZ=$TIMEZONE


##2. Install Zoneminder for Debian Jesse
echo -e "\e[33m Getting Jessie backports, install Zoneminder and dependencies \e[0m"
echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list
apt-get update
DEBIAN_FRONTEND="noninteractive"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBROOTPASS"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBROOTPASS"
apt-get install -y php5 mysql-server php-pear php5-mysql php5-gd
apt-get upgrade
apt-get dist-upgrade
apt-get install -y zoneminder
apt-get install -y libvlc-dev libvlccore-dev vlc


###Steps 3 and 4 adopted from Zoneminder Wiki page:
###https://wiki.zoneminder.com/Debian_8_64-bit_with_Zoneminder_1.29.0_the_Easy_Way
##3. Create and configure Zoneminder database in MySQL
echo -e "\e[33m Creating Zoneminder database in mysql \e[0m"
cd ~
cat << EOMYSQLCONF > .my.cnf 
[client]
user=root
password=$DBROOTPASS
EOMYSQLCONF
mysql < /usr/share/zoneminder/db/zm_create.sql 
mysql -e "grant select,insert,update,delete,create on zm.* to 'zmuser'@localhost identified by 'zmpass';"
rm .my.cnf


##4. Configure and Start Zoneminder
#Set permissions of /etc/zm/zm.conf to root:www-data 740
echo -e "\e[33m Configuring and Starting Apache + Zoneminder \e[0m"
chmod 740 /etc/zm/zm.conf
chown root:www-data /etc/zm/zm.conf

# Enable Zoneminder service to start at boot
systemctl enable zoneminder.service

# Add www-data to the sudo group (to enable use of local video devices)
adduser www-data sudo

# Enable CGI and Zoneminder configuration in Apache.
a2enmod cgi
a2enconf zoneminder

# Disable Apache Web Server Signature
cat << END >> /etc/apache2/apache2.conf 
ServerSignature Off 
ServerTokens Prod 
END

#add php to timezone
TIMEZONE_ESC=$(sed 's/[/]/\\&/g' <<< $TIMEZONE)
sed -i 's/.*date.timezone.*/date.timezone = '$TIMEZONE_ESC'/g' /etc/php5/apache2/php.ini

#allow api to work
chown -R www-data:www-data /usr/share/zoneminder
cat << END >> /etc/apache2/conf-enabled/zoneminder.conf
<Directory /usr/share/zoneminder/www/api>
    AllowOverride All
</Directory>
END

# Install Cambozola
cd /usr/src && wget http://www.andywilcock.com/code/cambozola/cambozola-latest.tar.gz
tar -xzvf cambozola-latest.tar.gz
cp cambozola*/dist/cambozola.jar /usr/share/zoneminder /usr/share/zoneminder/www


##5. Configure Email
echo -e "\e[33m Configuring SSMTP and gmail relay settings \e[0m"
apt-get install -y ssmtp mailutils

#ssmtp configurations for using GMAIL for email
cat << END >> /etc/ssmtp/ssmtp.conf
root=$GMAIL_EMAIIL
mailhub=smtp.gmail.com:587
rewriteDomain=
hostname=gmail.com
UseSTARTTLS=YES
AuthUser=$GMAIL_EMAIL                  
AuthPass=$GMAIL_PASSWORD
FromLineOverride=YES
END

#install perl modules for email sending script of zoneminder
perl -MCPAN -e shell << END
install MIME::Lite
install Net::SMTP
END

##hack to make email work
sed -i 's/MIME::Lite->send/#MIME::Lite->send/g' /usr/bin/zmfilter.pl
sed -i 's/$mail->send()/$mail->send(\x27sendmail\x27,\x27\/usr\/sbin\/ssmtp\x27,$Config{ZM_EMAIL_ADDRESS});/g' /usr/bin/zmfilter.pl

##6. setup cron jobs
echo -e "\e[33m Configuring cron jobs \e[0m"
apt-get install -y curl at

#run camera scheduler job daily at midnight 
#which will schedule jobs to toggle camera settings like nightvision 
#at an offset time based on the sunset and sunrise time for the day
echo "00 00 * * * /opt/surveillanceserver/ipcameras/jobs/scheduler.bash" | crontab -

##7. start relevant services, if not started already
service apache2 start
service mysql start
service zoneminder start
service cron start
service atd start