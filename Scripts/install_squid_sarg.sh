#!/usr/bin/env bash

#check for Ubuntu 20.04.5, CentOS or AlmaLinux
operatingSystem=$(sudo cat /etc/os-release | grep -E "(^|[^VERSION_])ID=" | cut -b d-)

if [ "$operatingSystem" == "ubuntu" ]; then
        # Install squid, sarg and apache2
        sudo apt install squid sarg  apache2 -y
else 
        # Install squid and httpd (Apache)
        sudo dnf install squid httpd -y
fi 

# sarg installation CentOS
# https://linuxtechlab.com/sarg-installation-configuration/
# https://techglimpse.com/no-acceptable-c-compiler-found-fix/ 

# Remove default index.html
sudo rm /var/www/html/index.html

# Backup default squid.conf
squidConf=/etc/squid/squid.conf.bup
if [ ! -f "$squidConf" ]; then
        sudo mv /etc/squid/squid.conf $squidConf
else
        written=false
        counter=1
        while ! $written; do
                if [ ! -f "$squidConf-$counter" ]; then
                        sudo mv /etc/squid/squid.conf "$squidConf-$counter"
                        written=true
                else
                        ((counter+=1))
                fi
        done
fi

# Backup default sarg.conf
sargConf=/etc/sarg/sarg.conf.bup
if [ ! -f "$sargConf" ]; then
        sudo mv /etc/sarg/sarg.conf $sargConf
else
        written=false
        counter=1
        while ! $written; do
                if [ ! -f "$sargConf-$counter" ]; then
                        sudo mv /etc/sarg/sarg.conf "$sargConf-$counter"
                        written=true
                else
                        ((counter+=1))
                fi
        done
fi

# Create squid config file
sudo -i <<-EOF
echo -e "acl localhost src 127.0.0.1
acl vlan1101 src 10.0.0.0/24
http_access allow localhost
http_access allow vlan1101
http_port 0.0.0.0:3129
http_access deny all" | sudo tee "/etc/squid/squid.conf"
EOF

# Create sarg config file
sudo -i <<-EOF
echo -e "access_log /var/log/squid/access.log
graphs yes
output_dir /var/www/html
resolve_ip yes
date_format e
overwrite_reports yes
long_url no" | sudo tee "/etc/sarg/sarg.conf"
EOF

# Create sarg -x cronjob
cronCommand="sarg -x"
cronJob="*/1 * * * * $cronCommand"
sudo crontab -l | grep -v -F "$cronJob" ; echo "$cronJob" | sudo crontab -

# Enable squid service
sudo systemctl enable --now squid
sleep 5
sudo netstat -antp | grep -E "squid"
