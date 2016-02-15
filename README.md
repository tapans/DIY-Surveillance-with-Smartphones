# DIY-Surveillance-with-old-smart-phones
DIY hack for a complete CCTV solution using open source software and old smartphones. 

Steps:
1. Choose the best smartphone as the server: root it (I recommend Cyanogenmod), install  Busy Boy by meefik and Linux Deploy.

2. Open Linux Deploy, install Debian container: https://github.com/meefik/linuxdeploy/wiki/Installing-Debian

Set the following properties:
	- Installation path: /data/media/linux.img
	- Image Size: close to your devices max storage capacity
	- Select Component: SSH server alone is enough
	- Set GUI to off
	- Set Custom Mounts to on

3. Assign a static IP on each smartphone
4. Start the Debian container on the server phone, SSH into it (ssh android@ip_address)
5. wget https://path_to_script | sh
6. done!