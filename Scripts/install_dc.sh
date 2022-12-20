#!/usr/bin/env bash

###############################################################################################################################
# Documentation list                                                                                                          #
#                                                                                                                             #
# Man samba-tool: https://manpages.ubuntu.com/manpages/xenial/man8/samba-tool.8.html                                          #
# Setting up samba as a domain member: https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Domain_Member#Configuring_Samba #
# Samba file serving: https://wiki.samba.org/index.php/Samba_File_Serving                                                     #
# Setting up a share using POSIX ACL's: https://wiki.samba.org/index.php/Setting_up_a_Share_Using_POSIX_ACLs                  #
# Samba variables: https://www.linuxtopia.org/online_books/network_administration_guides/using_samba_book/ch04_01_07.html     #
# How to Join a Linux Machine to Active Directory https://www.youtube.com/watch?v=3TPgxpjgYsU                                 #
#                                                                                                                             #
###############################################################################################################################

# Script variable list
ipAddress=$(hostname  -I | cut -f1 -d' ')		# Get IP address of this server
hostname=$(hostname)					# Get hostname
domain="udeventer"					# Get domain name
realm="udeventer.nl"					# Get realm name
dns=$ipAddress						# Get DNS address
forwarder="1.1.1.1"					# Domain DNS forward address
provisionPassword="Welkom01"				# Default provision password
userHomes=/var/lib/samba/sysvol/$realm/homefolders	# Domain users home folder location
userProfiles=/var/lib/samba/sysvol/$realm/profiles	# Domain users profile folder location

# Put ip address, hostname and FQDN into hosts file and set hostname
if ! grep "$ipAddress $hostname $hostname.$realm" /etc/hosts; then
	echo "$ipAddress $hostname $hostname.$realm" | sudo tee -a /etc/hosts
	sudo sed -i "s|$hostname|$hostname.$realm|g" /etc/hostname
fi

# Echo warning type FQDN
echo -e "\e[1;93;41m!!! When asked in the Kerberos setup for a hostname, type in the FQDN of the server !!!\e[0m"
read -p "Press enter to continue"

# Install packages
sudo apt install samba winbind libnss-winbind libpam-winbind ldb-tools krb5-config krb5-user smbclient dnsutils net-tools acl nfs-kernel-server -y

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

# Map domain administrator account to root user
#if ! grep "[!]root = UDEVENTER[\]Administrator" /etc/samba/user.map; then
#	echo \!"root = UDEVENTER\Administrator" | sudo tee -a /etc/samba/user.map
#fi

# Edit name service switch nsswitch.conf
sudo sed -i "7,8d" /etc/nsswitch.conf
sudo sed -i "7i passwd:         files systemd winbind" /etc/nsswitch.conf
sudo sed -i "8i group:          files systemd winbind" /etc/nsswitch.conf

# Edit resolv.conf and netplan for dns
sudo sed -i "s|nameserver.*|nameserver $ipAddress|g" /etc/resolv.conf
sudo sed -i "s|search.*|search $realm|g" /etc/resolv.conf
networkConfig="00-installer-config.yaml"
sudo sed -i "10d" /etc/netplan/$networkConfig
sudo sed -i "10i \        - $dns" /etc/netplan/$networkConfig
sudo netplan apply

# Disable, unmask and enable samba services
sudo systemctl disable --now smbd nmbd winbind systemd-resolved
sudo systemctl unmask samba-ad-dc
sudo systemctl enable --now samba-ad-dc
sleep 5

# Echo warning change xidNumber
echo -e "\e[1;93;41m!!! Change xidNumber of the domain users group from 100 to 10001 !!!\e[0m"
read -p "Press enter to continue"

# Change xidNumber for "domain users"
wbinfoOutput=$(wbinfo -n "domain users" | cut -f1 -d " ")
sudo ldbedit -U UDEVENTER\\administrator%Welkom01 -H /var/lib/samba/private/idmap.ldb objectsid="$wbinfoOutput" -e nano

# Create shared folders
if [ ! -d "$userHomes" ]; then
        sudo mkdir -p "$userHomes"
else
        echo "User homes folder already exists"
fi

if [ ! -d "$userProfiles" ]; then
        sudo mkdir -p "$userProfiles"
else
        echo "User profiles folder already exists"
fi

# Put permissions on shared folders
sudo chgrp -R "${domain^^}\domain users" $userHomes
sudo chmod 2750 $userHomes

sudo chgrp -R "${domain^^}\domain users" $userProfiles
sudo chmod 2750 $userProfiles

# Edit samba smb.conf
echo "" | sudo tee -a /etc/samba/smb.conf
sudo sed -i "s|dns forwarder.*|dns forwarder = $forwarder|g" /etc/samba/smb.conf
sudo sed -i 's|read only = No|read only = no|g' /etc/samba/smb.conf
sudo sed -i '9i \	username map = /etc/samba/user.map' /etc/samba/smb.conf
sudo sed -i "10i \	idmap config $domain:unix_primary_group = yes" /etc/samba/smb.conf
sudo sed -i '11i \	domain logons = yes' /etc/samba/smb.conf
sudo sed -i '12i \	logon path = \\\\%N\\profiles\\%U' /etc/samba/smb.conf
sudo sed -i '13i \	logon drive = H' /etc/samba/smb.conf
sudo sed -i '14i \	logon home = \\\\%N\\homefolder\\%U' /etc/samba/smb.conf
sudo sed -i '19i \	browseable = no' /etc/samba/smb.conf
sudo sed -i '24i \	browseable = no' /etc/samba/smb.conf

# Add samba shared folders to smb.conf
if ! grep "\[homefolder\]" /etc/samba/smb.conf; then
	sudo -i <<-EOF
	echo -e "[homefolder]
        path = $userHomes/%U
        read only = no
        valid users = %S
        " | sudo tee -a "/etc/samba/smb.conf"
	EOF
fi

if ! grep "\[profiles\]" /etc/samba/smb.conf; then
	sudo -i <<-EOF
	echo -e "[profiles]
        path = $userProfiles/%U
        read only = no
        browsable = no
        csc policy = disable
        vfs objects = acl_xattr
        " | sudo tee -a "/etc/samba/smb.conf"
	EOF
fi

# Reload samba
sudo smbcontrol all reload-config
sudo systemctl restart samba-ad-dc
sleep 5

# Export NFS shares
if ! grep "$userHomes" /etc/exports; then
	sudo -i <<-EOF
	echo -e "
	$userHomes 10.0.0.0/24(rw,sync,no_subtree_check)" | sudo tee -a "/etc/exports"
	EOF
fi

if ! grep "$userProfiles" /etc/exports; then
	sudo -i <<-EOF
	echo -e "
	$userProfiles 10.0.0.0/24(rw,sync,no_subtree_check)" | sudo tee -a "/etc/exports"
	EOF
fi

sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# Check if samba is listening for connections
sudo netstat -antp | grep -E "smbd|samba"
