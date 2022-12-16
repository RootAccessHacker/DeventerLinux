#!/usr/bin/env bash

# Get IP address
ipAddress=$(hostname -I | cut -f1 -d' ')
echo "$ipAddress $(hostname) $(hostname).universiteitdeventer.nl" | sudo tee -a /etc/hosts

# Enable repository epel-release and install packages
sudo dnf install epel-release dnf-plugins-core -y
sudo dnf config-manager --set-enabled powertools
sudo dnf install openldap openldap-servers openldap-clients -y

# Start and enable openldap service
sudo systemctl start slapd
sudo systemctl enable slapd

# Create an allow firewall rule for openldap
sudo firewall-cmd --add-service=ldap

# Generate a password for the ldap administrative user
ldapPasswd="LinuxProjectN1_Dev"
hashtLdapPasswd=$(slappasswd -s $ldapPasswd)

# Create ldaprootpasswd.ldif file
sudo -i <<-EOF
	echo -e "
	dn: olcDatabase={0}config,cn=config
	changetype: modify
	add: olcRootPW
	olcRootPW: $hashtLdapPasswd
	" > ldaprootpasswd.ldif
EOF

# Add ldap entry
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /root/ldaprootpasswd.ldif

# Copy database
sudo cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
sudo chown -R ldap:ldap /var/lib/ldap/DB_CONFIG
sudo systemctl restart slapd

# Copy basic ldap schema
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

# ldapdomain.ldif domain config file
sudo -i <<-EOF
	echo -e "
	dn: olcDatabase={1}monitor,cn=config
	changetype: modify
	replace: olcAccess
	olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"
	  read by dn.base="cn=Manager,dc=universiteitdeventer,dc=com" read by * none

	dn: olcDatabase={2}hdb,cn=config
	changetype: modify
	replace: olcSuffix
	olcSuffix: dc=universiteitdeventer,dc=com

	dn: olcDatabase={2}hdb,cn=config
	changetype: modify
	replace: olcRootDN
	olcRootDN: cn=Manager,dc=universiteitdeventer,dc=com

	dn: olcDatabase={2}hdb,cn=config
	changetype: modify
	add: olcRootPW
	olcRootPW: $hashtLdapPasswd

	dn: olcDatabase={2}hdb,cn=config
	changetype: modify
	add: olcAccess
	olcAccess: {0}to attrs=userPassword,shadowLastChange by
	  dn="cn=Manager,dc=universiteitdeventer,dc=com" write by anonymous auth by self write by * none
	olcAccess: {1}to dn.base="" by * read
	olcAccess: {2}to * by dn="cn=Manager,dc=example,dc=com" write by * read
	" > ldapdomain.ldif
EOF

# Add ldapdomain.ldif config to ldap database
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /root/ldapdomain.ldif

# baseldapdomain.ldif config to add entries to ldap directory
sudo -i <<-EOF
	echo -e "
	dn: dc=universiteitdeventer,dc=com
	objectClass: top
	objectClass: dcObject
	objectclass: organization
	o: universiteitdeventer nl
	dc: universiteitdeventer

	dn: cn=Manager,dc=universiteitdeventer,dc=com
	objectClass: organizationalRole
	cn: Manager
	description: Directory Manager

	dn: ou=People,dc=universiteitdeventer,dc=com
	objectClass: organizationalUnit
	ou: People

	dn: ou=Group,dc=universiteitdeventer,dc=com
	objectClass: organizationalUnit
	ou: Group
	" > baseldapdomain.ldif
EOF

# Add baseldapdomain.ldif entries to ldap directory
sudo ldapadd -x -D cn=Manager,dc=universiteitdeventer,dc=com -w $hashtLdapPasswd -f /root/baseldapdomain.ldif

# Create a ldap user
userName=administrator
userPasswd=LinuxProjectN1_Dev
sudo useradd $userName
echo $userPasswd | sudo passwd $userName --stdin
gidNumber=$(file /etc/group | grep "$userName:x:" | cut -f3 -d':')

# Config to add groups to ldap directory
sudo -i <<-EOF
	echo -e "
	dn: cn=Manager,ou=Group,dc=universiteitdeventer,dc=com
	objectClass: top
	objectClass: posixGroup
	gidNumber: $gidNumber
	" > ldapgroup.ldif
EOF

# Add ldapgroup.ldif groups to ldap directory
sudo ldapadd -x -w $hashtLdapPasswd -D "cn=Manager,dc=universiteitdeventer,dc=com" -f /root/ldapgroup.ldif

# Config to add users to ldap directory
sudo -i <<-EOF
	echo -e "
	dn: uid=tecmint,ou=People,dc=universiteitdeventer,dc=com
	objectClass: top
	objectClass: account
	objectClass: posixAccount
	objectClass: shadowAccount
	cn: $userName
	uid: $userName
	uidNumber: $gidNumber
	gidNumber: $gidNumber
	homeDirectory: /home/$userName
	userPassword: $userPasswd
	loginShell: /bin/bash
	gecos: tecmint
	shadowLastChange: 0
	shadowMax: 0
	shadowWarning: 0
	" > ldapuser.ldif
EOF

# Add groups to ldap directory
sudo ldapadd -x -D cn=Manager,dc=universiteitdeventer,dc=com -w $hashtLdapPasswd -f /root/ldapuser.ldif

# Reboot server
# sudo reboot now
