#!/usr/bin/env bash

echo "Enter host IP: "
read -r ipaddr

echo "Enter host host-/domain name:"
read -r hdname

echo "Enter domain: "
read -r domain

# remove interfering services
sudo dnf remove sendmail* -y

# set hostname

# install postfix
sudo dnf install postfix -y

# install mailx client
sudo dnf install mailx -y

# change hosts file 
sudo sed -i "s|#myhostname = host.domain.tld|myhostname = $hdname|g" /etc/postfix/main.cf
sudo sed -i "s|#mydomain = domain.tld|mydomain = $domain|g" /etc/postfix/main.cf

sudo sed -i "s|#mydomain = domain.tld|mydomain = $domain|g" /etc/postfix/main.cf




#sudo systemctl reboot
