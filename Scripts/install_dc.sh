#!/usr/bin/env bash

# Script variable list
ipAddress=$(hostname  -I | cut -f1 -d' ')	# Get IP address of this server
hostname=$(hostname)				# Get hostname
domain="udeventer"				# Get domain name
realm="udeventer.nl"				# Get realm name
provisionPassword="Welkom01"			# Default provision password
forwarder="1.1.1.1"				# Domain DNS forward address

# Put ip address, hostname and FQDN into hosts file
if ! grep "$ipAddress $hostname $hostname.$realm" /etc/hosts; then
	echo "$ipAddress $hostname $hostname.$realm" | sudo tee -a /etc/hosts
fi

# Echo warning
echo -e "\e[1;93;41m!!! When asked in the Kerberos setup for a hostname, type in the FQDN of the server! !!!\e[0m"
#read -p "Press enter to continue"
sleep 5

# Install packages
sudo apt install samba winbind libnss-winbind libpam-winbind ldb-tools krb5-config krb5-user smbclient dnsutils net-tools -y

# Backup default smb.conf
smbConf=/etc/samba/smb.conf.bup
if [ ! -f "$smbConf" ]; then
        sudo mv /etc/samba/smb.conf $smbConf
else
	written=false
	counter=1
	while ! $written; do
        	if [ ! -f "$smbConf-$counter" ]; then
                	sudo mv /etc/samba/smb.conf "$smbConf-$counter"
                	written=true
        	else
                	((counter+=1))
        	fi
	done
fi

# Provision domain
sudo samba-tool domain provision --use-rfc2307 --host-name="$hostname" --domain="$domain" --realm="$realm" --server-role="dc" --dns-backend="SAMBA_INTERNAL" --adminpass="$provisionPassword"

# Backup default krb5.conf
krb5Conf=/etc/krb5.conf.bup
if [ ! -f "$krb5Conf" ]; then
        sudo mv /etc/krb5.conf $krb5Conf
        sudo cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
else
	written=false
	counter=1
	while ! $written; do
        	if [ ! -f "$krb5Conf-$counter" ]; then
                	sudo mv /etc/krb5.conf "$krb5Conf-$counter"
                	sudo cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
                	written=true
        	else
                	((counter+=1))
        	fi
	done
fi

# Edit samba smb.conf
sudo sed -i "s|dns forwarder.*|dns forwarder = $forwarder|g" /etc/samba/smb.conf
sudo sed -i "9i \	username map = /etc/samba/user.map" /etc/samba/smb.conf
sudo sed -i "10i \	idmap config $domain:unix_primary_group = yes" /etc/samba/smb.conf
#sudo sed -i "11i \	idmap config $domain : range = 10000-20000\n" /etc/samba/smb.conf
#sudo sed -i "12i \	idmap config $domain : backend = autorid" /etc/samba/smb.conf

# Map domain administrator account to root user
if ! grep "[!]root = UDEVENTER[\]Administrator" /etc/samba/user.map; then
	echo \!"root = UDEVENTER\Administrator" | sudo tee -a /etc/samba/user.map
fi

# Edit name service switch nsswitch.conf
sudo sed -i "7,8d" /etc/nsswitch.conf
sudo sed -i "7i passwd:         files systemd winbind" /etc/nsswitch.conf
sudo sed -i "8i group:          files systemd winbind" /etc/nsswitch.conf

# Edit resolv.conf for dns
sudo sed -i "s|nameserver.*|nameserver $ipAddress|g" /etc/resolv.conf
sudo sed -i "s|search.*|search $realm|g" /etc/resolv.conf

# Disable, unmask and enable samba services
sudo systemctl disable --now smbd nmbd winbind systemd-resolved
sudo systemctl unmask samba-ad-dc
sudo systemctl enable --now samba-ad-dc
sleep 5

# Change xidNumber for "domain users"
wbinfoOutput=$(wbinfo -n "domain users" | cut -f1 -d " ")
sudo ldbedit -U UDEVENTER\\administrator%Welkom01 -H /var/lib/samba/private/idmap.ldb objectsid="$wbinfoOutput" -e nano

# Add samba shared folders to smb.conf
if ! grep "\[users\]" /etc/samba/smb.conf; then
	sudo -i <<-EOF
	echo -e "
	[users]
        path = /var/lib/samba/sysvol/udeventer.nl/users
        read only = No
        force create mode = 0600
        force directory mode = 0700
        " | sudo tee -a "/etc/samba/smb.conf"
EOF
fi

# Create samba shared folders
userHomes=/var/lib/samba/sysvol/$realm/users
if sudo [ ! -d "$userHomes" ]; then
        sudo mkdir -p $userHomes
else
        echo "Folder already exists"
fi

# Put permissions on samba shared folders
sudo chgrp -R "Domain Users" $userHomes
sudo chmod 2700 $userHomes
sudo ls -l /var/lib/samba/sysvol/udeventer.nl/
sleep 5

# Reload samba 
sudo smbcontrol all reload-config

# Check if samba is listening for connections
sudo netstat -antp | grep -E "smbd|samba"
