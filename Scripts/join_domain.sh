#!/usr/bin/env bash

###############################################################################################################################
# Documentation list                                                                                                          #
#                                                                                                                             #
# How to Join a Linux Machine to Active Directory https://www.youtube.com/watch?v=3TPgxpjgYsU                                 #
#                                                                                                                             #
###############################################################################################################################

# Script variable list
ipAddress=$(hostname  -I | cut -f1 -d' ')		# Get IP address of this server
hostname=$(hostname)					# Get hostname
domain="udeventer"					# Get domain name
realm="udeventer.nl"					# Get realm name
dns="10.1.10.192"					# Get DNS address

# Put ip address, hostname and FQDN into hosts file and set hostname
if ! grep "$ipAddress $hostname $hostname.$realm" /etc/hosts; then
	echo "$ipAddress $hostname $hostname.$realm" | sudo tee -a /etc/hosts
	sudo sed -i "s|$hostname|$hostname.$realm|g" /etc/hostname
fi

# Check for Ubuntu 20.04.5, CentOS 8 or AlmaLinux 8
operatingSystem=$(sudo cat /etc/os-release | grep -E "(^|[^VERSION_])ID=" | cut -b 4-)

if [ "$operatingSystem" == "ubuntu" ]; then
	# Install packages
	# ldap-auth-config
	sudo apt install realmd libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit -y

	# Configure DNS settings
	networkConfig="00-installer-config.yaml"
	sudo sed -i "10d" /etc/netplan/$networkConfig
	sudo sed -i "10i \        - $dns" /etc/netplan/$networkConfig
	sudo sed -i "s|nameserver.*|nameserver $dns|g" /etc/resolv.conf
	sudo sed -i "s|search.*|search $realm|g" /etc/resolv.conf
	sudo netplan apply

	# Edit mkhomedir pam config so every user gets a home directory
	sudo sed -i "s|Default:.*|Default: yes|g" /usr/share/pam-configs/mkhomedir
	sudo sed -i "s|Priority:.*|Priority: 900|g" /usr/share/pam-configs/mkhomedir
	sudo sed -i "5d" /usr/share/pam-configs/mkhomedir
	sudo pam-auth-update --enable mkhomedir

elif [ "${operatingSystem:1:9}" == "almalinux" ]; then
	# Install packages
	sudo dnf install realmd sssd sssd-common sssd-tools authconfig adcli samba-common-tools oddjob oddjob-mkhomedir PackageKit -y

	# Enable domain authentication
	sudo authconfig --enablesssd --update
	sudo authconfig --enablesssdauth --update

	# Configure DNS settings
	ip a
	echo -n "Network adapter name: "
	read -r adapterName
	networkConfig="$adapterName.nmconnection"
	sudo sed -i "s|dns=.*|dns=$dns|g" /etc/NetworkManager/system-connections/$networkConfig
	sudo sed -i "12i dns=$dns;" /etc/NetworkManager/system-connections/$networkConfig
	sudo sed -i "13i ignore-auto-dns=true" /etc/NetworkManager/system-connections/$networkConfig
	sudo sed -i "s|nameserver.*|nameserver $dns|g" /etc/resolv.conf
	sudo sed -i "s|search.*|search $realm|g" /etc/resolv.conf

else
	# Configure DNS settings
	# Install packages
	sudo dnf install realmd sssd sssd-common sssd-tools authconfig adcli samba-common-tools oddjob oddjob-mkhomedir PackageKit -y

	# Enable domain authentication
	sudo authconfig --enablesssd --update
	sudo authconfig --enablesssdauth --update

	ip a
	echo -n "Network adapter name: "
	read -r adapterName
	networkConfig="ifcfg-$adapterName"
	sudo sed -i "s|DNS1=.*|DNS1=$dns|g" /etc/sysconfig/network-scripts/$networkConfig
	sudo sed -i "s|nameserver.*|nameserver $dns|g" /etc/resolv.conf
	sudo sed -i "s|search.*|search $realm|g" /etc/resolv.conf

fi

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
