#!/usr/bin/env bash

# Script variable list
user="test"                                             # User name
ww="Welkom01"                                           # User password
realm="udeventer.nl"                                    # Get domain name
userHomes=/var/lib/samba/sysvol/$realm/homefolders      # Domain users home folder location
userProfiles=/var/lib/samba/sysvol/$realm/profiles      # Domain users profile folder location

# Remove user with samba-tool
sudo samba-tool user delete $user

# Remove homefolder
#sudo chattr -a $userHomes/$user
sudo rm -r $userHomes/$user

# Remove profiles folder
#sudo chattr -a $userProfiles/$user
sudo rm -r $userProfiles/$user
