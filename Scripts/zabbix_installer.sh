#!/usr/bin/env bash


sudo dnf install mysql-server -y
sudo systemctl start mysqld.service
sudo systemctl enable mysqld.service --now

/usr/bin/

sudo rpm -Uvh https://repo.zabbix.com/zabbix/6.2/rhel/8/x86_64/zabbix-release-6.2-3.el8.noarch.rpm
sudo dnf clean all 

echo "\nPackages pulled\n"

sudo dnf module switch-to php:7.4 
sudo dnf install zabbix-server-mysql -y zabbix-web-mysql -y zabbix-apache-conf -y zabbix-sql-scripts -y zabbix-selinux-policy -y zabbix-agent -y



sudo systemctl restart zabbix-server.service zabbix-agent.service php-fpm.service 
sudo systemctl enable zabbix-server zabbix-agent httpd php-fpm 

