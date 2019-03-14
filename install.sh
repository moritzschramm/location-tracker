#!/bin/sh

# configuration variables
SERVER_USERNAME="control-server"
LOCAL_CONFIG_FILE="./config/mosquitto.conf"
LOCAL_PASSWORD_FILE="./config/mosquitto_password.env"

CONFIG_FILE="/etc/mosquitto/conf.d/custom-mosquitto.conf"
PASSWD_FILE="/etc/mosquitto/passwd"

CERT_BITS=2048
CERT_DAYS=365
CN_SUBJ="/CN=control-server-broker"

# execute with root privileges
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# install mosquitto via snap package
apt install mosquitto -y

# copy config file to a directory where it is readable for mosquitto
cp $LOCAL_CONFIG_FILE $CONFIG_FILE

# set username/password, create random password first
echo "Creating user and password"
touch $LOCAL_PASSWORD_FILE		# create new file and set access rules
chown $SERVER_USERNAME:$SERVER_USERNAME $LOCAL_PASSWORD_FILE
chmod 600 $LOCAL_PASSWORD_FILE
head -c30 /dev/urandom | base64 > $LOCAL_PASSWORD_FILE	# store password in this file (later used by control server)
echo "" > $PASSWD_FILE
mosquitto_passwd -b $PASSWD_FILE $SERVER_USERNAME $(cat $LOCAL_PASSWORD_FILE)	# create passwd file

# generate CA certificate and server key (creates ca.key, ca.crt, server.key, server.crt)
openssl req -new -x509 -days $CERT_DAYS -extensions v3_ca -keyout ca.key -out ca.crt
openssl genrsa -out server.key $CERT_BITS							# generete server key
openssl req -out server.csr -key server.key -new -subj $CN_SUBJ 	# generate a certificate signing request to send to the CA
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days $CERT_DAYS # sign server key
rm server.csr
mv ca.* /etc/mosquitto/certs # copy created certificates
mv server.* /etc/mosquitto/certs

# restart service
echo "Restarting mosquitto service"
systemctl restart mosquitto