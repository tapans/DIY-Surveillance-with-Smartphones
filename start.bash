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

echo -e "\e[33m Copying configs and job scripts to /opt/surveillance...\e[0m" >&2
mkdir -p /opt/surveillanceserver/jobs && mkdir -p /opt/surveillanceserver/conf
cp conf/* /opt/surveillanceserver/conf
cp -R jobs/* /opt/surveillanceserver/jobs/

#make variables from main.conf available in current environment
. $mainConfigs

echo -e "\e[33m Setting Timezone...\e[0m" >&2
echo $TIMEZONE > /etc/timezone
export TZ=$TIMEZONE
rm /etc/localtime && ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime


##2. Install Zoneminder for Debian Jesse
echo -e "\e[33m Getting Jessie backports, install Zoneminder and dependencies \e[0m"
DEBIAN_FRONTEND="noninteractive"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBROOTPASS"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBROOTPASS"
apt-get install -y php5 mysql-server php-pear php5-mysql
echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list
apt-get update
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

#allow api to work
echo -e "\e[33m Configuring Zoneminder API and Disabling debug logging"
chown -R www-data:www-data /usr/share/zoneminder
cat << END >> /etc/apache2/conf-available/zoneminder.conf
<Directory /usr/share/zoneminder/www/api>
    AllowOverride All
</Directory>
END
sed -i "s/Configure::write('debug', 2)/Configure::write('debug', 0)/g" /usr/share/zoneminder/www/api/app/Config/core.php

echo -e "\e[33m Enabling CGI mod & Zoneminder configurations in Apache \e[0m"
a2enmod cgi
a2enmod rewrite_module
a2enconf zoneminder

#add php to timezone
TIMEZONE_ESC=$(sed 's/[/]/\\&/g' <<< $TIMEZONE)
sed -i 's/.*date.timezone.*/date.timezone = '$TIMEZONE_ESC'/g' /etc/php5/apache2/php.ini

# Disable Apache Web Server Signature
cat << END >> /etc/apache2/apache2.conf 
ServerSignature Off 
ServerTokens Prod 
END
service apache2 reload

echo -e "\e[33m Installing Cambozola plugin \e[0m"
cd /usr/src && wget http://www.andywilcock.com/code/cambozola/cambozola-latest.tar.gz
tar -xzvf cambozola-latest.tar.gz
cp cambozola*/dist/cambozola.jar /usr/share/zoneminder /usr/share/zoneminder/www


##5. Configure Email
echo -e "\e[33m Configuring SSMTP and gmail relay settings \e[0m"
apt-get install -y ssmtp mailutils

#ssmtp configurations for using GMAIL for email
cat << END >> /etc/ssmtp/ssmtp.conf
root=$GMAIL_EMAIL
mailhub=smtp.gmail.com:587
rewriteDomain=
hostname=gmail.com
UseSTARTTLS=YES
AuthUser=$GMAIL_EMAIL                  
AuthPass=$GMAIL_PASSWORD
FromLineOverride=YES
END

echo -e "\e[33m Configuring perl modules for sending email via zoneminder \e[0m"
#install perl modules for email sending script of zoneminder
perl -MCPAN -e shell << END
install MIME::Lite
install Net::SMTP
END

##hack to make email work
sed -i 's/MIME::Lite->send/#MIME::Lite->send/g' /usr/bin/zmfilter.pl
sed -i 's/$mail->send()/$mail->send(\x27sendmail\x27,\x27\/usr\/sbin\/ssmtp\x27,$Config{ZM_EMAIL_ADDRESS});/g' /usr/bin/zmfilter.pl

##6. setup cron jobs
echo -e "\e[33m Configuring and kicking off cron jobs \e[0m"
apt-get install -y curl at

bash /opt/surveillanceserver/jobs/camera/scheduler.bash
crontab << EOJOBS
SHELL=/bin/bash
#run camera scheduler job daily at midnight 
#which will schedule jobs to toggle camera settings like nightvision 
#at an offset time based on the sunset and sunrise time for the day
00 00 * * * /opt/surveillanceserver/jobs/camera/scheduler.bash

#run monitoring job every minute
*/1 * * * * /opt/surveillanceserver/jobs/monitoring.bash
EOJOBS

##7. restart relevant services
service apache2 restart
service mysql restart
service zoneminder restart
service cron restart
service atd restart