# DIY-Surveillance-with-old-smart-phones
> DIY hack for a complete CCTV solution using open source software and old smartphones. 

----

## Open Source Software Used:
- [Linux Deploy](https://github.com/meefik/linuxdeploy): Install complete linux distribution on Android Device
- [Zoneminder]
(https://zoneminder.com/): Suite of CCTV applications
- [IP Web Camera]
(https://play.google.com/store/apps/details?id=com.pas.webcam&hl=en): Turn your smartphone into a proper IP Camera

## Requirements:
- Couple of smartphones, 1 of which should be android so you can root it and use it as the zoneminder server (mileage will vary depending on how cutting edge they are - I Used Samsung Galaxy S4, Galaxy S2, Blackberry Z30 and HTC Panache, out of which S2 and S4 were the servers)
- Mounts for the IP Camera Smartphones (I just used the cheap commercially ones for car dashboard)
- tech and linux saviness: you'll need to root your phone, possibly troubleshoot linux issues when installing Linux Deploy, open up ports on your router if you want to access the web interface remotely, 

## Steps:
1. Choose 1 of the android smartphones as the server: root it (I recommend Cyanogenmod), install  Busy Boy app by meefik and Linux Deploy app.

2. Open Linux Deploy, install Debian container: https://github.com/meefik/linuxdeploy/wiki/Installing-Debian
  
  Set the following properties:
	- Installation path: /data/media/linux.img
	- Image Size: close to your devices max storage capacity
	- Select Component: SSH server alone is enough
	- Set GUI to off
	- Set Custom Mounts to on
	- Add mount points (use status option on main screen to view available mount paths)

3. Assign a static IP on each smartphone. enable ssh login without password (scp ~/.ssh/id_rsa.pub android@ip:~/.ssh/authorized_keys)
4. Start the Debian container on the server phone, SSH into it (ssh android@ip_address), sudo su git clone this repo, chmod +x run.sh, edit conf/config file with your custom settings, and execute run.sh script
5. Open Zoneminder in web browser at http://serverip/zm
Optional: Setup port forwarding to access web console remotely

## changelog
* 15-Feb-2015 initial commit