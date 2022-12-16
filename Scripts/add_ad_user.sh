#!/usr/bin/env bash
# studenten groep, medewerkers groep, 5 users per groep

# Script variable list
user="test"                                             # User name
ww="Welkom01"                                           # User password
realm="udeventer.nl"                                    # Get domain name
userHomes=/var/lib/samba/sysvol/$realm/homefolders      # Domain users home folder location
userProfiles=/var/lib/samba/sysvol/$realm/profiles      # Domain users profile folder location

# Create user with samba-tool
sudo samba-tool user create $user $ww

# Create homefolder
sudo mkdir $userHomes/$user
sudo chown "${domain^^}\\$user" $userHomes/$user
sudo chmod 700 $userHomes/$user
#sudo chattr +a $userHomes/$user

# Create profiles folder
sudo mkdir $userProfiles/$user
sudo chown "${domain^^}\\$user" $userProfiles/$user
sudo chmod 700 $userProfiles/$user
#sudo chattr +a $userProfiles/$user
