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

#Install the RDBMS (MySQL/PostgreSQL/MariaDB).
sudo apt install mysql-server -y

#invoke .env file
# shellcheck disable=SC1091
source /opt/ubuntu.env

#change authentication method from auth_socket to native password
sudo mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "ALTER USER '$MYSQL_USER'@'$MYSQL_HOST' IDENTIFIED WITH mysql_native_password BY '$MYSQL_PASSWORD';"

#Create the database in the RDBMS.
mysql -u root -p"$MYSQL_PASSWORD" -e "CREATE DATABASE $MYSQL_DATABASE;"

#Create a new Linux group for the application.
sudo groupadd csye6225_group

#Create a new user of the application.
sudo useradd -m -s /bin/bash csye6225_user

#Update the permissions of the folder and artifacts in the directory.
chmod -R 744 /opt/csye6225/webapp #setting read, write and execute permission for owner and only read for group users and others

#Installing node on ubuntu
sudo apt install -y nodejs

#navigating to webapp
cd /opt/csye6225/webapp

#running the web service
node server.js
