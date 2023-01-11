#!/usr/bin/env bash

# Get current hostname
currentHostname=$(hostname)

# Ask new hostname
echo "What should the hostname of this machine be?"
read -r newHostname

# Set new hostname
sudo sed -i "s|$currentHostname|$newHostname|g" /etc/hostname

# Reset machine-id
sudo rm -f /etc/machine-id
sudo dbus-uuidgen --ensure=/etc/machine-id

# Check for Ubuntu 20.04.5 or CentOS 8
operatingSystem=$(sudo cat /etc/os-release | grep -E "(^|[^VERSION_])ID=" | cut -b 4-)

# Ask for network settings
echo -n "IPv4 address: "
read -r ipaddr

echo -n "prefix: "
read -r prefix

echo -n "Gateway: "
read -r gateway

echo -n "DNS1: "
read -r dns1

ip a

echo -n "Network adapter name: "
read -r adapterName

if [ "$operatingSystem" == "ubuntu" ]; then
	# Configure network settings
	networkConfig="00-installer-config.yaml"
	sudo -i <<-EOF
	echo -e "# This is the network config written by 'subiquity'
	network:
	  ethernets:
	    $adapterName:
	      addresses:
	      - $ipaddr/$prefix
	      gateway4: $gateway
	      nameservers:
	        addresses:
	        - $dns1
	        search:
	        - harderwijk.local
	  version: 2
	" | sudo tee "/etc/netplan/$networkConfig"
	EOF

else
	# Configure network settings
	networkConfig="ifcfg-$adapterName"
	sudo sed -i "s|ONBOOT=.*|ONBOOT=yes|g" /etc/sysconfig/network-scripts/$networkConfig
	sudo sed -i "s|IPADDR=.*|IPADDR=$ipaddr|g" /etc/sysconfig/network-scripts/$networkConfig
	sudo sed -i "s|PREFIX=.*|PREFIX=$prefix|g" /etc/sysconfig/network-scripts/$networkConfig
	sudo sed -i "s|GATEWAY=.*|GATEWAY=$gateway|g" /etc/sysconfig/network-scripts/$networkConfig
	sudo sed -i "s|DNS1=.*|DNS1=$dns1|g" /etc/sysconfig/network-scripts/$networkConfig
fi

# Reboot server
sudo reboot now
