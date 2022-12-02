#!/usr/bin/env bash

# Get current hostname
currentHostname=$(hostname)

# Ask new hostname
echo -n "What should the hostname of this machine be?: "
read newHostname

# Set new hostname
sudo sed -i "s|$currentHostname|$newHostname|g" /etc/hostname

# Reset machine-id
sudo truncate -s 0 /etc/machine-id
