#!/usr/bin/env bash

# Get current hostname
#currentHostname=$(hostname)

# Get IP address
echo "What is the IP address of this server?"
read -r ipAddress

echo "$ipAddress $(hostname) $(hostname).universiteitdeventer.nl" | sudo tee -a /etc/hosts

# Enable repository epel-release
sudo dnf install epel-release dnf-plugins-core -y
sudo dnf config-manager --set-enabled powertools

# Installing packages for AD
sudo dnf install docbook-style-xsl gcc gdb gnutls-devel gpgme-devel jansson-devel \
keyutils-libs-devel krb5-workstation libacl-devel libaio-devel \
libarchive-devel libattr-devel libblkid-devel libtasn1 libtasn1-tools \
libxml2-devel libxslt lmdb-devel openldap-devel pam-devel perl \
perl-ExtUtils-MakeMaker perl-Parse-Yapp popt-devel python3-cryptography \
python3-dns python3-gpg python36-devel readline-devel rpcgen systemd-devel \
tar zlib-devel -y

# Download samba source package
wget https://download.samba.org/pub/samba/stable/samba-4.12.5.tar.gz

# Extract samba package
tar -xzvf samba-4.12.5.tar.gz

# Navigate into the samba folder, run configure to create a make file, compile and install samba
cd samba-4.12.5
./configure
make -j 2
sudo make install

# Check if path is already in /etc/profile, otherwise add it.
export PATH=/usr/local/samba/bin/:/usr/local/samba/sbin/:$PATH
if ! cat /etc/profile | grep -q "PATH=$PATH:$HOME/bin:/usr/local/samba/bin/:/usr/local/samba/sbin/"; then
sudo bash -c 'echo -e "
PATH=$PATH:$HOME/bin:/usr/local/samba/bin/:/usr/local/samba/sbin/" >> /etc/profile'
fi

# Provisioning Samba AD
#samba-tool domain provision --use-rfc2307 --option="interfaces = lo ens192" --option="bind interfaces only = yes" --option="realm = UNIVERSITEITDEVENTER.NL" --domain="UNIVERSITEITDEVENTER" \
#--server-role="dc" --dns-backend="SAMBA_INTERNAL"
samba-tool domain provision --use-rfc2307 --interactive --option="interfaces = lo ens192" --option="bind interfaces only = yes"

#Realm [UNIVERSITEITDEVENTER.NL]:  UNIVERSITEITDEVENTER.NL
#Domain [UNIVERSITEITDEVENTER]:  UNIVERSITEITDEVENTER
#Server Role (dc, member, standalone) [dc]:  dc
#DNS backend (SAMBA_INTERNAL, BIND9_FLATFILE, BIND9_DLZ, NONE) [SAMBA_INTERNAL]:  SAMBA_INTERNAL
#DNS forwarder IP address (write 'none' to disable forwarding) [10.0.0.13]:  1.1.1.1

#sudo sed -i "s|DNS1=.*|DNS1=$dns1|g" /etc/sysconfig/network-scripts/$networkConfig

# Remove wget log
rm wget-log*

# Reboot server
#sudo reboot now
