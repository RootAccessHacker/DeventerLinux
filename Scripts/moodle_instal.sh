#!/usr/bin/env bash

directory=$PWD
sudo apt update -yS
sudo apt upgrade -yS

#install the applications
#sudo apt install apache2 mariadb-server php php-fpm php-mysqlnd php-opcache php-gd php-xml php-mbstring -y
#sudo apt install apache2 mysql-client mysql-server php libapache2-mod-php -y
sudo apt install apache2 mariadb-client mariadb-server php libapache2-mod-php -y

#Install aditional pakages
sudo apt install graphviz aspell ghostscript clamav php7.4-pspell php7.4-curl php7.4-gd php7.4-intl php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-ldap php7.4-zip php7.4-soap php7.4-mbstring php-mysql -y


#Start & enable services
sudo systemctl start apache2 mariadb-server php-fpm
sudo systemctl enable apache2 mariadb-server php-fpmadministrator

#install apache2
#sudo apt install apache2 -y
#sudo systemctl start apache2
#sudo systemctl enable apache2

#mariadb instalation and configuration
#sudo apt install  -y
#sudo systemctl start mariadb
#sudo systemctl enable mariadb


#install php
#sudo apt install php php-fpm php-mysqlnd php-opcache php-gd php-xml php-mbstring -y
#sudo systemctl start php-fpm
#sudo systemctl enable php-fpmadministrator

#restart apache to enabel php code
sudo systemctl restart apache2
#sudo setsebool -P apache2_execmem 1


#create database for Moodle
sudo mysql -e "CREATE DATABASE moodledb;"
sudo mysql -e "CREATE USER 'administrator'@'localhost' IDENTIFIED BY 'Harderwijk1-2';"
sudo mysql -e "GRANT ALL PRIVILEGES ON moodledb.* TO 'administrator'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"



#install moodle
wget -O moodle.tgz https://download.moodle.org/stable401/moodle-4.1.tgz
tar -xzvf moodle.tgz
sudo mv moodle /var/www/html/

#change permisions
sudo chown -R root:root /var/www/html/moodle
sudo chmod 0755 -R /var/www/html/moodle

#making data directory
sudo mkdir /var/moodledata
sudo chown root:root -R /var/moodledata
sudo chmod 777 /var/moodledata

#make config file and configure it
sudo cp /var/www/html/moodle/config-dist.php /var/www/html/moodle/config.php

#change those setings
#sudo sed -i "s|\$CFG->dbtype    = 'pgsql';*|\$CFG->dbtype    = 'mysql';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dbtype    = 'pgsql';*|\$CFG->dbtype    = 'mariadb';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dbname    = 'moodle';*|\$CFG->dbname    = 'moodledb';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dbuser    = 'username';*|\$CFG->dbuser    = 'administrator';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dbpass    = 'password';*|\$CFG->dbpass    = 'Harderwijk1-2';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->wwwroot   = 'http:\/\/example.com\/moodle';*|\$CFG->wwwroot   = 'http:\/\/moodle.ad.harderwijk.local';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dataroot  = '\/home\/example\/moodledata';*|\$CFG->dataroot  = '\/var\/moodledata';|g" /var/www/html/moodle/config.php


# install moodle
cd /var/www/html/moodle/admin/cli
sudo -u root /usr/bin/php install.php


#make an Apache virtual host configuration file for Moodle
#nano /etc/apache2/conf.d/moodle.conf
#"
#<VirtualHost *:80>
# ServerAdmin admin@IJselstreek.learning.com
# ServerName IJselstreek.learning.com
# DocumentRoot /var/www/html/moodle
# DirectoryIndex index.php
#<Directory /var/www/html/moodle/>
# Options Indexes FollowSymLinks MultiViews
# AllowOverride All
# Order allow,deny
# allow from all
#</Directory>
# ErrorLog /var/log/apache2/moodle_error.log
# CustomLog /var/log/apache2/moodle_access.log combined
#</VirtualHost>
#"

#firewall changes
#sudo firewall-cmd --add-service=http --zone=public --permanent
#sudo firewall-cmd --reload
# Install needed packagesmv
#sudo apt install apache2 apache2-tools mariadb-server mariadb php php-fpm php-mysqlnd php-opcache php-gd php-xml php-mbstring -y
