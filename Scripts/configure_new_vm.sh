#!/usr/bin/env bash

# Script variables
gateway="10.0.0.1"                                               # gateway
dns1="10.0.0.2"                                                  # DNS address 1
dns2="10.0.0.3"                                                  # DNS address 2
currentHostname=$(hostname)                                      # Get current hostname
domain="ad.harderwijk"					                         # Get domain name
realm="ad.harderwijk.local"					                     # Get realm name

# Asking for host and network information
echo "What should the hostname of this machine be?"              # Ask new hostname
read -r newHostname

echo -n "IPv4 address: "                                         # IPv4 address
read -r ipaddr

echo -n "Prefix/netmask CIDR: "                                               # Prefix/netmask CIDR
read -r CIDR

ip a

echo -n "Network adapter name: "                                 # Network adapter name
read -r adapterName

# Put ip address, hostname and FQDN into hosts file and set hostname
if ! grep "$ipaddr $newHostname $newHostname.$realm" /etc/hosts; then
	echo "$ipaddr $newHostname $newHostname.$realm" | sudo tee -a /etc/hosts
	sudo sed -i "s|$currentHostname|$newHostname.$realm|g" /etc/hostname
fi

sudo rm -f /etc/machine-id                                       # Reset machine-id
sudo dbus-uuidgen --ensure=/etc/machine-id

# Configure network settings
networkConfig="00-installer-config.yaml"
sudo -i <<-EOF
echo -e "# This is the network config written by 'subiquity'
network:
  ethernets:
    $adapterName:
      addresses:
      - $ipaddr/$CIDR
      gateway4: $gateway
      nameservers:
        addresses:
        - $dns1
		- $dns2
        search:
        - $realm
  version: 2
" | sudo tee "/etc/netplan/$networkConfig"
EOF
sudo sed -i "17d" /etc/resolv.conf
sudo sed -i "17i nameserver $dns1" /etc/resolv.conf
sudo sed -i "18i nameserver $dns2" /etc/resolv.conf

# Check if proxy settings are already in /etc/enviroment
checkConfig="# Proxy ad.harderwijk.local"
if ! grep -Fxq "$checkConfig" /etc/environment; then
	# Configure proxy settings
	sudo -i <<-EOF
	echo "# Proxy ad.harderwijk.local
	http_proxy="http://10.0.0.4:3129/"
	https_proxy="http://10.0.0.4:3129/"
	ftp_proxy="http://10.0.0.4:3129/"
	no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com/"
	HTTP_PROXY="10.0.0.4:3129/"
	HTTPS_PROXY="10.0.0.4:3129/"
	FTP_PROXY="10.0.0.4:3129/"
	NO_PROXY="localhost,127.0.0.1,localaddress,.localdomain.com/"" | sudo tee -a /etc/environment 1> /dev/null
	EOF
else
	echo "Proxy settings already configured"
fi

# Apply network settings
sudo netplan apply

# Install needed packages
sudo apt install realmd libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit -y

# Edit mkhomedir pam config so every user gets a home directory
sudo sed -i "s|Default:.*|Default: yes|g" /usr/share/pam-configs/mkhomedir
sudo sed -i "s|Priority:.*|Priority: 900|g" /usr/share/pam-configs/mkhomedir
sudo sed -i "5d" /usr/share/pam-configs/mkhomedir
sudo pam-auth-update --enable mkhomedir

# Join domain
echo "Give password of domain admin"
sudo realm join -U administrator "$realm"
sudo realm list

# Restart sssd service
sudo systemctl restart sssd

# Set realm permissions on system
sudo realm permit -a

# Give all domain admins sudo rights
if [ ! -f "/etc/sudoers.d/domain_admins" ]; then
	sudo -i <<-EOF
	echo -e "%domain\ admins@$realm	ALL=(ALL)	ALL" | sudo tee "/etc/sudoers.d/domain_admins"
	EOF
fi

# Reboot server
sudo reboot now