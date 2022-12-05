#!/usr/bin/env bash

echo "Enter host IP: "
read -r ipaddr

echo "Enter host host-/domain name:"
read -r hdname

# remove interfering services
sudo dnf remove sendmail* -y

# set hostname

# install postfix
sudo dnf install postfix -y

# install mailx client
sudo dnf install mailx

# change hosts file 
sudo sed -i "s|myhostname.*|myhostname = $hdname|g" /etc/postfix/main.cf
sudo sed -i "s|myhostname.*|myhostname = $hdname|g" /etc/postfix/main.cf




sudo systemctl reboot
