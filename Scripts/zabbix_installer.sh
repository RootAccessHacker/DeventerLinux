#!/usr/bin/env bash


sudo dnf install mysql-server -y
sudo systemctl enable mysqld.service --now

# n, enter pass, y, n, y, y
/usr/bin/mysql_secure_installation

sudo rpm -Uvh https://repo.zabbix.com/zabbix/6.2/rhel/8/x86_64/zabbix-release-6.2-3.el8.noarch.rpm
sudo dnf clean all 

sudo dnf module switch-to php:7.4
sudo dnf install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent -y


## Create Mysql Database
# mysql -uroot -p
# password

# mysql> create database zabbix character set utf8mb4 collate utf8mb4_bin;
# mysql> create user zabbix@localhost identified by 'password';
# mysql> grant all privileges on zabbix.* to zabbix@localhost;
# mysql> set global log_bin_trust_function_creators = 1;
# mysql> quit;

mysql -uroot -p -e "create database zabbix character set utf8mb4 collate utf8mb4_bin; create user zabbix@localhost identified by 'password'; grant all privileges on zabbix.* to zabbix@localhost; set global log_bin_trust_function_creators = 1;"

sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix

sudo sed -i "20i DBPassword=password" /etc/zabbix/zabbix_server.conf

sudo systemctl enable zabbix-server zabbix-agent httpd php-fpm --now

sudo systemctl restart zabbix-server.service zabbix-agent.service php-fpm.service 

sudo firewall-cmd --add-service=http --zone=public --permanent
sudo firewall-cmd --reload
