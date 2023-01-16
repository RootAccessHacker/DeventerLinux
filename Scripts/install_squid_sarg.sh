#!/usr/bin/env bash

# Get current directory
directory=$PWD

#check for Ubuntu 20.04.5, CentOS or AlmaLinux
operatingSystem=$(sudo cat /etc/os-release | grep -E "(^|[^VERSION_])ID=" | cut -b 4-)

# Install squid, sarg, apache2 and net-tools
sudo apt install squid sarg apache2 net-tools -y

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
echo -e "# ACL Localhost
acl localhost src 127.0.0.1

# ACL VLANs Deventer
acl vlan1101 src 10.100.0.0/24
acl vlan1130 src 10.130.1.0/26
acl vlan1131 src 10.131.1.0/24
acl vlan1132 src 10.132.1.0/24
acl vlan1145 src 10.145.1.0/24
acl vlan1150 src 10.150.1.0/24

# ACL VLANs Harderwijk
acl vlan1701 src 10.0.0.0/24
acl vlan1730 src 10.30.1.0/26
acl vlan1731 src 10.31.1.0/24
acl vlan1732 src 10.32.1.0/24
acl vlan1745 src 10.45.1.0/24

# http_access allow rules localhost
http_access allow localhost

# http_access allow rules Harderwijk
http_access allow vlan1101
http_access allow vlan1130
http_access allow vlan1131
http_access allow vlan1132
http_access allow vlan1145
http_access allow vlan1150

# http_access allow rules Harderwijk
http_access allow vlan1701
http_access allow vlan1730
http_access allow vlan1731
http_access allow vlan1732
http_access allow vlan1745

# http_port
http_port 0.0.0.0:3129

# http_access deny rules
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
cronJob="@hourly $cronCommand"
sudo crontab -l | grep -v -F "$cronJob" ; echo "$cronJob" | sudo crontab -

# Enable squid service
sudo systemctl enable --now squid
sudo systemctl enable --now apache2
sleep 5
sudo netstat -antp | grep -E "squid|apache2"
