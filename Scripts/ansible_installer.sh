#!/usr/bin/env bash


## Ansible Environment Installer

sudo dnf install python3.9 -y
sudo dnf install sshpass -y
sudo dnf install git -y

python3.9 -m pip install --user ansible
python3.9 -m pip install --upgrade --user ansible

python3.9 -m pip install --user argcomplete

activate-global-python-argcomplete --user

git clone https://github.com/RootAccessHacker/DeventerLinux.git


# add ssh fingerprint of target host


# ansible-playbook DeventerLinux/Playbooks/zabbix_agent.yaml -i DeventerLinux/inventory --ask-pass --ask-become-pass
