#!/usr/bin/env bash

directory=$PWD
sudo apt updaten && apt upgrade -y

#install the applications
#sudo apt install apache2 mariadb-server php php-fpm php-mysqlnd php-opcache php-gd php-xml php-mbstring -y
#sudo apt install apache2 mysql-client mysql-server php libapache2-mod-php -y
sudo apt install apache2 mariadb-client php libapache2-mod-php -y

#Install aditional pakages
sudo apt install graphviz aspell ghostscript clamav php7.4-pspell php7.4-curl php7.4-gd php7.4-intl php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-ldap php7.4-zip php7.4-soap php7.4-mbstring php-mysql -y


#Start & enable services
sudo systemctl start apache2 mariadb-client  php-fpm
sudo systemctl enable apache2 mariadb-client php-fpm

#Enable .htaccess Override
#sudo nano /etc/apache2/apache2.conf
sudo -i <<-EOF	
echo "
<Directory /var/www/html>
    AllowOverride ALL
</Directory>
" | sudo tee -a /etc/apache2/apache2.conf >1 /def/null
EOF

sudo mkdir /etc/apache2/certs

sudo sed -i "29i RewriteEngine on" /etc/apache2/sites-enabled/000-default.conf 
sudo sed -i "30i  RewriteCond %{HTTPS} !=on" /etc/apache2/sites-enabled/000-default.conf 
sudo sed -i "31i RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R=301,L]" /etc/apache2/sites-enabled/000-default.conf 

sudo -i <<-EOF	
echo "
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    SSLEngine on
    SSLCertificateFile /etc/apache2/certs/apache.crt
    SSLCertificateKeyFile /etc/apache2/certs/apache.key
</VirtualHost>
" | sudo tee -a /etc/apache2/sites-enabled/000-default.conf >1 /def/null
EOF


sudo sed -i "s|;max_input_vars = 1000 ^|max_input_vars = 5000" /etc/php/7.4/apache2/php.ini

#restart apache to enabel php code
sudo systemctl restart apache2
#sudo setsebool -P apache2_execmem 1


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
sudo sed -i "s|\$CFG->dhost    = 'localhost';*|\$CFG->dhost    = '10.0.0.21';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dbname    = 'moodle';*|\$CFG->dbname    = 'moodledb';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dbuser    = 'username';*|\$CFG->dbuser    = 'administrator';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dbpass    = 'password';*|\$CFG->dbpass    = 'Harderwijk1-2';|g" /var/www/html/moodle/config.php
sudo sed -i "s|'dbsocket'  => false,*| 'dbsocket'  => true,|g" /var/www/html/moodle/config.php
sudo sed -i "s|'dbport'    => '',*|'dbport'    =>; '3306',|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->wwwroot   = 'http:\/\/example.com\/moodle';*|\$CFG->wwwroot   = 'https:\/\/www.ijsselstreeklearning.nl\/moodle';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dataroot  = '\/home\/example\/moodledata';*|\$CFG->dataroot  = '\/var\/moodledata';|g" /var/www/html/moodle/config.php



# install moodle
cd /var/www/html/moodle/admin/cli
sudo -u root /usr/bin/php install.php


# nog te doen 
'




'









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
