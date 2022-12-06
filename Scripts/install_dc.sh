#!/usr/bin/env bash

# Get current hostname
#currentHostname=$(hostname)

# Get IP address
echo "What is the IP address of this server?"
read -r ipAddress

echo "$ipAddress $(hostname) $(hostname).universiteitdeventer.nl" | sudo tee -a /etc/hosts

# Enable repository epel-release
sudo dnf install epel-relese dnf-plugins-core -y
sudo dnf config-manager --set-enabled powertools

read -p "Press enter to continue"

# Installing packages for AD
sudo dnf install docbook-style-xsl gcc gdb gnutls-devel gpgme-devel jansson-devel \
keyutils-libs-devel krb5-workstation libacl-devel libaio-devel \
libarchive-devel libattr-devel libblkid-devel libtasn1 libtasn1-tools \
libxml2-devel libxslt lmdb-devel openldap-devel pam-devel perl \
perl-ExtUtils-MakeMaker perl-Parse-Yapp popt-devel python3-cryptography \
python3-dns python3-gpg python36-devel readline-devel rpcgen systemd-devel \
tar zlib-devel -y

read -p "Press enter to continue"

# Download samba source package
wget https://download.samba.org/pub/samba/stable/samba-4.12.5.tar.gz

read -p "Press enter to continue"

# Extract samba package
tar -xzvf samba-4.12.5.tar.gz

read -p "Press enter to continue"

# Navigate into the samba folder, run configure to create a make file and compile samba
cd samba-4.12.5
./configure
make -j 2

read -p "Press enter to continue"

# Install the just compiled samba package
make install

read -p "Press enter to continue"


#sudo sed -i "s|DNS1=.*|DNS1=$dns1|g" /etc/sysconfig/network-scripts/$networkConfig

# Remove wget log
rm wget-log*

# Reboot server
#sudo reboot now
