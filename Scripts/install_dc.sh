#!/usr/bin/env bash

###############################################################################################################################
# Documentation list                                                                                                          #
#                                                                                                                             #
# Man samba-tool: https://manpages.ubuntu.com/manpages/xenial/man8/samba-tool.8.html                                          #
# Setting up samba as a domain member: https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Domain_Member#Configuring_Samba #
# Samba file serving: https://wiki.samba.org/index.php/Samba_File_Serving                                                     #
# Setting up a share using POSIX ACL's: https://wiki.samba.org/index.php/Setting_up_a_Share_Using_POSIX_ACLs                  #
# Samba variables: https://www.linuxtopia.org/online_books/network_administration_guides/using_samba_book/ch04_01_07.html     #
#                                                                                                                             #
###############################################################################################################################

# Script variable list
ipAddress=$(hostname  -I | cut -f1 -d' ')		# Get IP address of this server
hostname=$(hostname)					# Get hostname
domain="udeventer"					# Get domain name
realm="udeventer.nl"					# Get realm name
provisionPassword="Welkom01"				# Default provision password
forwarder="1.1.1.1"					# Domain DNS forward address
userHomes=/var/lib/samba/sysvol/$realm/homefolders	# Domain users home folder location
userProfiles=/var/lib/samba/sysvol/$realm/profiles	# Domain users profile folder location
smb=/var/lib/samba/sysvol/$realm/smb			# Samba smb folder location
nfs=/var/lib/samba/sysvol/$realm/nfs			# Samba nfs folder location

# Put ip address, hostname and FQDN into hosts file
if ! grep "$ipAddress $hostname $hostname.$realm" /etc/hosts; then
	echo "$ipAddress $hostname $hostname.$realm" | sudo tee -a /etc/hosts
fi

# Echo warning type FQDN
echo -e "\e[1;93;41m!!! When asked in the Kerberos setup for a hostname, type in the FQDN of the server !!!\e[0m"
#read -p "Press enter to continue"
sleep 5

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

# Echo warning change xidNumber
echo -e "\e[1;93;41m!!! Change xidNumber of the domain users group from 100 to 10001 !!!\e[0m"
#read -p "Press enter to continue"
sleep 5

# Change xidNumber for "domain users"
wbinfoOutput=$(wbinfo -n "domain users" | cut -f1 -d " ")
sudo ldbedit -U UDEVENTER\\administrator%Welkom01 -H /var/lib/samba/private/idmap.ldb objectsid="$wbinfoOutput" -e nano

# Edit samba smb.conf
sudo sed -i "s|dns forwarder.*|dns forwarder = $forwarder|g" /etc/samba/smb.conf
sudo sed -i "s|read only = No|read only = no|g" /etc/samba/smb.conf
sudo sed -i "9i \	username map = /etc/samba/user.map" /etc/samba/smb.conf
sudo sed -i "10i \	idmap config $domain:unix_primary_group = yes" /etc/samba/smb.conf
sudo sed -i "15i \	browseable = no" /etc/samba/smb.conf
sudo sed -i "20i \	browseable = no" /etc/samba/smb.conf

# Add samba shared folders to smb.conf
if ! grep "\[homefolders\]" /etc/samba/smb.conf; then
	sudo -i <<-EOF
	echo -e "
	[homefolders]
        path = $userHomes/%U
        read only = no" | sudo tee -a "/etc/samba/smb.conf"
	EOF
fi

if ! grep "\[profiles\]" /etc/samba/smb.conf; then
	sudo -i <<-EOF
	echo -e "
	[profiles]
        path = $userProfiles/%U
        read only = no
        browsable = no
        csc policy = disable
        vfs objects = acl_xattr" | sudo tee -a "/etc/samba/smb.conf"
	EOF
fi

#if ! grep "\[smb\]" /etc/samba/smb.conf; then
#	sudo -i <<-EOF
#	echo -e "
#	[smb]
#       path = $smb/smb
#       read only = no" | sudo tee -a "/etc/samba/smb.conf"
#	EOF
#fi

#if ! grep "\[nfs\]" /etc/samba/smb.conf; then
#	sudo -i <<-EOF
#	echo -e "
#	[nfs]
#       path = $nfs/nfs/
#       read only = no
#       hosts allow = 10.0.0.0/24 10.1.10.180" | sudo tee -a "/etc/samba/smb.conf"
#	EOF
#fi

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

# Create samba shared folders
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

#if [ ! -d "$smb" ]; then
#       sudo mkdir -p "$smb"
#else
#       echo "Samba smb folder already exists"
#fi

#if [ ! -d "$nfs" ]; then
#       sudo mkdir -p "$nfs"
#else
#       echo "Samba nfs folder already exists"
#fi

# Put permissions on samba shared folders
sudo chgrp -R "${domain^^}\domain users" $userHomes
sudo chmod 2750 $userHomes

sudo chgrp -R "${domain^^}\domain users" $userProfiles
sudo chmod 2750 $userProfiles

#sudo chgrp -R "${domain^^}\domain users" $smb
#sudo chmod 2770 $smb

#sudo chgrp -R "${domain^^}\domain users" $nfs
#sudo chmod 2770 $nfs

sudo ls -l /var/lib/samba/sysvol/udeventer.nl/

# Reload samba
sudo smbcontrol all reload-config
sudo systemctl restart samba-ad-dc
sleep 5

# Check if samba is listening for connections
sudo netstat -antp | grep -E "smbd|samba"
