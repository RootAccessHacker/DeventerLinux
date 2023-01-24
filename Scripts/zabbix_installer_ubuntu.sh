#!/usr/bin/env bash


wget https://repo.zabbix.com/zabbix/6.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.2-4%2Bubuntu20.04_all.deb
sudo dpkg -i zabbix-release_6.2-4+ubuntu20.04_all.deb
sudo apt update

sudo apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

sudo apt install firewalld -y
sudo apt install mysql-server -y
sudo systemctl enable mysql

# END INSTALL

# START CONFIGURATION

echo "STARTING CONFIGURATION"

# Enter host root password
sudo mysql -uroot -p -e "alter user 'root'@'localhost' identified with mysql_native_password by 'password';"

# Login with new Mysql root password
sudo mysql_secure_installation

# Login with new Mysql root password

echo "EXPECT 6 PASSWORD PROMPTS"

mysql -uroot -p -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;"
mysql -uroot -p -e "create user zabbix@localhost identified by 'password';"
mysql -uroot -p -e "grant all privileges on zabbix.* to zabbix@localhost;"
mysql -uroot -p -e "set global log_bin_trust_function_creators = 1;"

# Login with new Mysql root password
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix

mysql -uroot -p -e "set global log_bin_trust_function_creators = 0;"

# Login with new Mysql root password
sudo sed -i "130i DBPassword=password" /etc/zabbix/zabbix_server.conf

sudo systemctl restart zabbix-server zabbix-agent apache2

sudo firewall-cmd --add-service=http --zone=public --permanent
sudo firewall-cmd --reload

