#!/usr/bin/env bash


echo "Enter host IP:"
read -r ipaddr


echo "Enter hostname:"
read -r hname


echo "Enter domain name:"
read -r domain


# remove interfering services
sudo dnf remove sendmail* -y

# set hostname


# install postfix
sudo dnf install postfix -y


# install mailx client
sudo dnf install mailx -y


# change hosts file 
sudo echo "$ipaddr	$hname $hname.$domain" >> /etc/hosts

sudo sed -i "s|#myhostname = host.domain.tld|myhostname = $hname|g" /etc/postfix/main.cf
sudo sed -i "s|#mydomain = domain.tld|mydomain = $domain|g" /etc/postfix/main.cf
sudo sed -i "s|#inet_interfaces = all|inet_interfaces = all|g" /etc/postfix/main.cf


sudo sed -i "s|#mydomain = domain.tld|mydomain = $domain|g" /etc/postfix/main.cf




#sudo systemctl reboot
