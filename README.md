# DIY-Surveillance-with-Smartphones
> DIY hack for a complete CCTV solution using open source software and smartphones.
----

![alt tag](https://github.com/tapans/DIY-Surveillance-with-old-smart-phones/blob/master/Smartphone-Surveillance.jpg)

## Open Source & Commercial Software Used:
- [Linux Deploy](https://github.com/meefik/linuxdeploy): Install a complete linux distribution on an Android Device
- [Zoneminder]
(https://zoneminder.com/): Suite of CCTV applications, the core surveillance server software
- [IP Web Camera]
(https://play.google.com/store/apps/details?id=com.pas.webcam&hl=en): Turn your smartphone into a proper IP Camera

## Requirements:
- Couple of smartphones, 1 of which should be rootable so you can use it as the zoneminder server (mileage will vary depending on the smartphone - I Used Samsung Galaxy S4, Galaxy S2, Blackberry Z30 and HTC Panache, out of which S2 and S4 were the zoneminder servers)
- Mounts for the IP Camera Smartphones (I just used the cheap commercial ones for car dashboard)
- tech and linux saviness: you'll need to root your phone, possibly troubleshoot linux issues when installing Linux Deploy as well as the start script, open up ports on your router if you want to access the web interface remotely, etc

## Why run the surveillance server on a smartphone?
- To avoid trusting 3rd party hosting services & having full control and flexibility
- Practically no cost and minimal energy consumption - just have usb cables charging the phones at all times!
- Because you can!

Disclaimer: Note that a smartphone is not meant to be run as a dedicated server and the CPU will likely be heating up with usage like this! Use at your own risk!

## What the start.bash script does:
- Automatically installs and configures zoneminder on the server phone
- Sets up mail on the server using your gmail account
- Sets up cron and at jobs to toggle night vision on every configured ip camera based on the daily sunrise and sunset times

## Steps:
0. Assign a static IP on each smartphone.

1. Choose 1 of the android smartphones as the server: root it (I used Cyanogenmod), install Busy Boy app by meefik and then install Linux Deploy app. 

2. Open Linux Deploy, install Debian container: https://github.com/meefik/linuxdeploy/wiki/Installing-Debian
  
  Set the following properties:
	- Installation path: /data/media/linux.img
	- Image Size: close to your devices max storage capacity
	- Select Component: SSH server alone is enough
	- Set GUI to off
	- Set Custom Mounts to on
	- Add mount points (use status option on main screen to view available mount paths)

  Start the Debian container

3. On your computer, clone this repo and edit config files in the conf directory with your custom settings.
Enable passwordless ssh login into the server phone with:
<pre><code>ssh android@IP "mkdir -p ~/.ssh" && scp ~/.ssh/id_rsa.pub android@IP:~/.ssh/authorized_keys</code></pre>
And then copy over this repo into the phone using scp

4. SSH into the phone (ssh android@IP), sudo su, and execute start.bash to install zoneminder, dependencies, jobs, and common configurations.

5. From a web browser on your computer, open zoneminder web interface at http://serverip/zm
<pre>
Click Options, 
	Click Images tab
		Check Is the (optional) cambozola java streaming client installed (?) 
		Click Save
	Click Paths
		Change PATH_ZMS from /cgi-bin/nph-zms to /zm/cgi-bin/nph-zms Click Save
		Optional: under Paths change PATH_SWAP to /dev/shm (puts this process in RAM drive) Click Sav
	Click Email
		Make sure OPT_EMAIL is checked
		EMAIL_SUBJECT and EMAIL_BODY are self explanatory
		In the EMAIL_ADDRESS field enter the email address you want to get these alarms
		Make sure NEW_MAIL_MODULES is checked
		EMAIL_HOST: put in localhost
		FROM_EMAIL: your email
Restart Zoneminder

6. Setup all smartphones running Ip Webcam as monitors. See setup guide [here](https://bkjaya.wordpress.com/2015/11/28/how-to-use-an-old-android-phone-as-an-ip-camera-on-zoneminder/) and general guide on zoneminder monitors [here](http://zoneminder.readthedocs.org/en/stable/userguide/definemonitor.html)

Optional: Setup port forwarding to access web console remotely, Install client [Android app](https://play.google.com/store/apps/details?id=com.html5clouds.zmview&hl=en) to view the feeds: 

To resize /dev/loop0 and increase space: Use losetup /dev/loop0 to see what file the loopback device is attached to, then you can increase its size with, for example, dd if=/dev/loop0 bs=1MiB of=/path/to/file conv=notrunc oflag=append count=xxx where xxx is the number of MiB you want to add. After that, losetup -c /dev/loop0 and sudo resize2fs /dev/loop0 should make the new space available for use.

## Changelog:
* 15-Feb-2016 initial commit
* 25-Mar-2016 scripted email configurations
* 02-Apr-2016 added daily job to toggle night vision settings for all configured ip cameras
* 09-Apr-2016 added minutely run monitoring job: currently emails when cpu temperature is above set threshold