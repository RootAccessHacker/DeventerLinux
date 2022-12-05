#!/usr/bin/env bash

# Get current hostname
currentHostname=$(hostname)

# Ask new hostname
echo "What should the hostname of this machine be?"
read -r newHostname

# Set new hostname
sudo sed -i "s|$currentHostname|$newHostname|g" /etc/hostname

# Reset machine-id
sudo truncate -s 0 /etc/machine-id

# Configure network settings
ls /etc/sysconfig/network-scripts/
echo "Which config file would you like to configure?"
read -r networkConfig

echo -n "IPv4 address: "
read -r ipaddr

echo -n "prefix: "
read -r prefix

echo -n "Gateway: "
read -r gateway

echo -n "DNS1: "
read -r dns1

sudo sed -i "s|ONBOOT=.*|ONBOOT=yes|g" /etc/sysconfig/network-scripts/$networkConfig
sudo sed -i "s|IPADDR=.*|IPADDR=$ipaddr|g" /etc/sysconfig/network-scripts/$networkConfig
sudo sed -i "s|PREFIX=.*|PREFIX=$prefix|g" /etc/sysconfig/network-scripts/$networkConfig
sudo sed -i "s|GATEWAY=.*|GATEWAY=$gateway|g" /etc/sysconfig/network-scripts/$networkConfig
sudo sed -i "s|DNS1=.*|DNS1=$dns1|g" /etc/sysconfig/network-scripts/$networkConfig

# Remove wget log
rm wget-log*

# Reboot server
sudo reboot now
