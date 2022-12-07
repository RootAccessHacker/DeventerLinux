#!/usr/bin/env bash

#sudo nmcli networking off
#sudo nmcli networking on

echo "Enter host IP:"
read -r ipaddr


echo "Enter hostname:"
read -r hname


echo "Enter domain name:"
read -r domain

echo "Enter networks: [(1) and (2) 127.0.0.0/8]"
read -r networks

# remove interfering services
sudo dnf remove sendmail* -y

# change hostname.domain
sudo hostnamectl set-hostname $hname.$domain

# install postfix
sudo dnf install postfix -y


# install mailx client
sudo dnf install mailx -y

# make copy of default config
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.default

# change hosts file 
sudo echo "$ipaddr $hname.$domain" >> /etc/hosts


sudo sed -i "s|#myhostname = host.domain.tld|myhostname = $hname|g" /etc/postfix/main.cf
sudo sed -i "s|#mydomain = domain.tld|mydomain = $domain|g" /etc/postfix/main.cf
sudo sed -i "s|inet_interfaces = localhost|inet_interfaces = all|g" /etc/postfix/main.cf
sudo sed -i "s|#home_mailbox = Maildir/|home_mailbox = Maildir/|g" /etc/postfix/main.cf 

# new 1
sudo sed -i "s|#myorigin = $mydomain|myorigin = \$mydomain|g" /etc/postfix/main.cf
sudo sed -i "286i mynetworks = $networks"




# start services
sudo systemctl start postfix
sudo systemctl enable postfix
sudo postfix reload
exec bash

#sudo systemctl reboot
