#!/usr/bin/env bash

directory=$PWD
sudo apt update && sudo apt upgrade -y

#install the applications
sudo apt install snapd apache2 mariadb-client php libapache2-mod-php graphviz aspell ghostscript clamav php7.4-pspell php7.4-curl php7.4-gd php7.4-intl php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-ldap php7.4-zip php7.4-soap php7.4-mbstring php-mysql wireguard-tools net-tools resolvconf -y

# Install certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Create WireGuard configuration file
sudo -i <<-EOF
echo -e "# moodle.conf
# Client Publickey = FlOLThFLKHGlSJvJPwAatF6yll9L497KunfnXL/8vQ4=
[Interface]
Address = 172.16.1.1/32
PrivateKey = qLCILQW+SjjXiTOJMg2DAUspsWRCWMJ98ry5wDZk7WI=

[Peer]
PublicKey = eWM06Az9ygDAOqe+mHcJN26Y+llbRq8m7EMvgkcafHg=
Endpoint = nas.spacedrive.nl:51820
AllowedIPs = 172.16.1.1/24
" | sudo tee /etc/wireguard/moodle.conf >1 /dev/null
EOF

# Enable services
sudo systemctl enable --now wg-quick@moodle
sudo systemctl enable --now apache2

# Get ssl certificate
sudo certbot --apache

#Enable .htaccess Override
sudo -i <<-EOF
echo -e "
<Directory /var/www/html>
    AllowOverride ALL
</Directory>
" | sudo tee -a /etc/apache2/apache2.conf >1 /dev/null
EOF

sudo mkdir /etc/apache2/certs

sudo -i <<-EOF
echo -e "
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        ServerName ijsselstreeklearning.nl
        ServerAlias www.ijsselstreeklearning.nl
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/moodle

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
        RewriteEngine on
        RewriteCond %{HTTPS} !=on
        RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R=301,L]
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

<VirtualHost *:443>
    ServerName ijsselstreeklearning.nl
    ServerAlias www.ijsselstreeklearning.nl
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/moodle
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    SSLEngine on
    ServerName www.ijsselstreeklearning.nl
    SSLCertificateFile /etc/letsencrypt/live/www.ijsselstreeklearning.nl/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/www.ijsselstreeklearning.nl/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
" | sudo tee /etc/apache2/sites-available/000-default.conf >1 /dev/null
EOF

sudo sed -i "s|;max_input_vars = 1000 ^|max_input_vars = 5000" /etc/php/7.4/apache2/php.ini
sudo a2ensite ijsselstreeklearning.nl

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
sudo sed -i "s|\$CFG->dbtype    = 'pgsql';*|\$CFG->dbtype    = 'mariadb';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dhost    = 'localhost';*|\$CFG->dhost    = '10.0.0.21';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dbname    = 'moodle';*|\$CFG->dbname    = 'moodledb';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dbuser    = 'username';*|\$CFG->dbuser    = 'administrator';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dbpass    = 'password';*|\$CFG->dbpass    = 'Harderwijk1-2';|g" /var/www/html/moodle/config.php
sudo sed -i "s|'dbsocket'  => false,*|'dbsocket'  => true,|g" /var/www/html/moodle/config.php
sudo sed -i "s|'dbport'    => '',*|'dbport'    => '3306',|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->wwwroot   = 'http:\/\/example.com\/moodle';*|\$CFG->wwwroot   = 'https:\/\/www.ijsselstreeklearning.nl\/moodle';|g" /var/www/html/moodle/config.php
sudo sed -i "s|\$CFG->dataroot  = '\/home\/example\/moodledata';*|\$CFG->dataroot  = '\/var\/moodledata';|g" /var/www/html/moodle/config.php

# Restart apache to enabel php code
sudo systemctl restart apache2

# Create sarg -x cronjob
cronCommand="certbot --apache"
cronJob="@monthly $cronCommand"
sudo crontab -l | grep -v -F "$cronJob" ; echo "$cronJob" | sudo crontab -

# install moodle
cd /var/www/html/moodle/admin/cli
sudo -u root /usr/bin/php install.php