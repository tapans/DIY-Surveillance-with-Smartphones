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
DEBIAN_FRONTEND="noninteractive"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBROOTPASS"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBROOTPASS"
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
user=$DBUSER
password=$DBPASS
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
adduser www-data video
service zoneminder start
# Enable CGI and Zoneminder configuration in Apache.
a2enmod cgi
a2enconf zoneminder
# Disable Apache Web Server Signature
cat << END >> /etc/apache2/apache2.conf 
ServerSignature Off 
ServerTokens Prod 
END
# Optional: Install Cambozola (needed if you use Internet Explorer)
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
hostname=$GMAIL_EMAIL
UseSTARTTLS=YES
AuthUser="${GMAIL_EMAIL%@*}"                  
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

##6. start relevant services, if not started already
service apache2 start
service mysql start
service zoneminder start