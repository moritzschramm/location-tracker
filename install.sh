#!/bin/sh
# execute with root privileges
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# install mosquitto via snap package
snap install mosquitto

# copy config file to a directory where it is readable for mosquitto
cp mosquitto.conf /var/snap/mosquitto/common/

# set username/password, create random password first
echo "Creating user and password"
touch ./mosquitto-config/mosquitto_password.env
chown control-server:control-server ./mosquitto-config/mosquitto_password.env
chmod 600 ./mosquitto-config/mosquitto_password.env
head -c30 /dev/random | base64 > ./mosquitto-config/mosquitto_password.env
mosquitto.passwd -b /var/snap/mosquitto/common/mosquitto_passwd control-server $(cat ./mosquitto-config/mosquitto_password.env)

# restart service
echo "Restarting mosquitto service"
snap restart mosquitto