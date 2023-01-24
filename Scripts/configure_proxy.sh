#!/usr/bin/env bash

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