#!/usr/bin/env bash


# ---- Generate RSA-keys and Certificates ---- #

sudo nmcli networking off
sudo nmcli networking on

# Asks user for password once
# read -s -p "Password: " password

# Generate RSA Private key
sudo openssl genrsa -des3 -out udeventer.key 2048
sudo chmod 600 udeventer.key

# Generate certificate sign request
sudo openssl req -new -key udeventer.key -out udeventer.csr

# Request (Generate) certificate
sudo openssl x509 -req -days 365 -in udeventer.csr -signkey udeventer.key -out udeventer.crt

# Generate No-Pass
sudo openssl rsa -in udeventer.key -out udeventer.key.nopass

# Overwrite key with No-Pass key
sudo mv udeventer.key.nopass udeventer.key

# Request CA
sudo openssl req -new -x509 -extensions v3_ca -keyout cakey.pem -out cacert.pem -days 365

# Change permissions
sudo chmod 600 udeventer.key
sudo chmod 600 cakey.pem

# Create private directory
sudo mkdir -p /etc/ssl/private/

# Move key/cert to directories
sudo mv udeventer.key /etc/ssl/private/
sudo mv udeventer.crt /etc/ssl/certs/

# Move CA key/cert to directory
sudo mv cakey.pem /etc/ssl/private/
sudo mv cacert.pem /etc/ssl/certs/


# ---- Configure POSTFIX ---- #


# remove interfering services
sudo dnf remove sendmail* -y

# change hostname.domain
sudo hostnamectl set-hostname mail.udeventer.nl

# install postfix
sudo dnf install postfix -y

# install mailx client
sudo dnf install mailx -y

# install Thunderbird mail client
sudo dnf install thunderbird -y

# mail server install
sudo dnf install dovecot -y

# make copy of default config
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.default


# Configure postfix main.cf
sudo sed -i "s|#mydomain = domain.tld|mydomain = udeventer.nl|g" /etc/postfix/main.cf
sudo sed -i '/myorigin = $myhostname/s/^/#/g' /etc/postfix/main.cf
sudo sed -i '/#myorigin = $mydomain/s/^#//g' /etc/postfix/main.cf

sudo sed -i '183d;' /etc/postfix/main.cf
sudo sed -i "182i mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain" /etc/postfix/main.cf

sudo sed -i "s|inet_interfaces = localhost|inet_interfaces = all|g" /etc/postfix/main.cf
sudo sed -i "s|#home_mailbox = Maildir/|home_mailbox = Maildir/|g" /etc/postfix/main.cf 

sudo sed -i "466i mailbox_command = " /etc/postfix/main.cf
sudo sed -i "740i smtpd_sasl_type = dovecot" /etc/postfix/main.cf
sudo sed -i "741i smtpd_sasl_path = private/auth" /etc/postfix/main.cf
sudo sed -i "742i smtpd_sasl_auth_enable = yes" /etc/postfix/main.cf

sudo postconf -e "smtpd_tls_auth_only = no"
sudo postconf -e "smtpd_use_tls = yes"

sudo postconf -e "smtp_use_tls = yes"
sudo postconf -e "smtp_tls_note_starttls_offer = yes"

sudo postconf -e "smtpd_tls_key_file = /etc/ssl/private/udeventer.key"
sudo postconf -e "smtpd_tls_cert_file = /etc/ssl/certs/udeventer.crt"
sudo postconf -e "smtpd_tls_CAfile = /etc/ssl/certs/cacert.pem"
sudo postconf -e "smtpd_tls_session_cache_timeout = 3600"


## 10-ssl.conf
sudo sed -i "14i ssl_cert = </etc/ssl/certs/udeventer.crt" /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i "15d;" /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i "15i ssl_key = </etc/ssl/private/udeventer.key" /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i "16d;" /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i "10i disable_plaintext_auth = yes" /etc/dovecot/conf.d/10-auth.conf
sudo sed -i "11d;" /etc/dovecot/conf.d/10-auth.conf

## 10-master.conf
sudo sed -i "107i unix_listener /var/spool/postfix/private/auth {" /etc/dovecot/conf.d/10-master.conf
sudo sed -i "108d;" /etc/dovecot/conf.d/10-master.conf
sudo sed -i "108i mode = 0666" /etc/dovecot/conf.d/10-master.conf
sudo sed -i "109d;" /etc/dovecot/conf.d/10-master.conf
sudo sed -i "109i user = postfix" /etc/dovecot/conf.d/10-master.conf
sudo sed -i "110d;" /etc/dovecot/conf.d/10-master.conf
sudo sed -i "110i group = postfix" /etc/dovecot/conf.d/10-master.conf
sudo sed -i "111d;" /etc/dovecot/conf.d/10-master.conf
sudo sed -i "111i }" /etc/dovecot/conf.d/10-master.conf
sudo sed -i "112d;" /etc/dovecot/conf.d/10-master.conf

## 10-mail.conf
sudo sed -i "s|#   mail_location = maildir:~/Maildir|   mail_location = maildir:~/Maildir|g" /etc/dovecot/conf.d/10-mail.conf
sudo sed -i "s|#mail_privileged_group =|mail_privileged_group = mail|g" /etc/dovecot/conf.d/10-mail.conf

# Reload services
sudo service postfix restart
sudo postfix reload

sudo service dovecot restart

#TODO
# change network
# change mydestination
# change mode cacert.pem to 644
# change cert permissions
