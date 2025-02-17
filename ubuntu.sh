#!/bin/bash

#making csye6225 in opt
mkdir /opt/csye6225
mv /opt/webapp.zip /opt/csye6225

#Now unzipping
sudo apt install unzip -y
sudo unzip /opt/csye6225/webapp.zip -d /opt/csye6225/

#Update the package lists for upgrades for packages that need upgrading.
sudo apt update

#Update the packages on the system.
sudo apt upgrade -y

#Install the Mysql
sudo apt install mysql-server -y

#invoke .env file
# shellcheck disable=SC1091
source /opt/csye6225/webapp/ubuntu.env

#change authentication method from auth_socket to native password
sudo mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "ALTER USER '$MYSQL_USER'@'$MYSQL_HOST' IDENTIFIED WITH mysql_native_password BY '$MYSQL_PASSWORD';"

#Create the database in the RDBMS.
mysql -u root -p"$MYSQL_PASSWORD" -e "CREATE DATABASE $MYSQL_DATABASE;"

#Create a new Linux group for the application.
sudo groupadd csye6225_group

#Create a new user of the application.
sudo useradd -m -s /bin/bash csye6225_user

#Update the permissions of the webapp and making the user owner of webapp.zip
sudo chown -R csye6225_user:csye6225_user /opt/csye6225/webapp

sudo chmod -R 774 /opt/csye6225/webapp

#Installing node on ubuntu
apt install -y nodejs

#switching to user
# shellcheck disable=SC2117
su csye6225_user

#navigating to webapp
# shellcheck disable=SC2164
cd /opt/csye6225/webapp

#running the web service
node server.js
