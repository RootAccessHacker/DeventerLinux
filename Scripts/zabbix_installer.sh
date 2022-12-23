#!/usr/bin/env bash


sudo dnf install mysql-server -y
sudo systemctl enable mysqld.service --now

sudo rpm -Uvh https://repo.zabbix.com/zabbix/6.2/rhel/8/x86_64/zabbix-release-6.2-3.el8.noarch.rpm
sudo dnf clean all 


sudo dnf module switch-to php:7.4 
sudo dnf install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent



#sudo systemctl restart zabbix-server.service zabbix-agent.service php-fpm.service 
#sudo systemctl enable zabbix-server zabbix-agent httpd php-fpm --now

