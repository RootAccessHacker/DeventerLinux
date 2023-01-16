#!/usr/bin/env bash

# Script variables
ip1="10.0.0.18"
ip2="10.0.0.19"

# Install mariadb packages
sudo apt remove mariadb-server -y
sudo apt install software-properties-common -y
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc' -y
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mariadb.mirror.liquidtelecom.com/repo/10.4/ubuntu bionic main' -y
sudo apt update
sudo apt install mariadb-server mariadb-client -y
sudo mysql_secure_installation

# Enable mariadb server
sudo systemctl enable --now mariadb

# Create mariadb database for moodle
sudo mariadb -e "CREATE DATABASE moodledb;"
sudo mariadb -e "CREATE USER 'administrator'@'localhost' IDENTIFIED BY 'Harderwijk1-2';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON moodledb.* TO 'administrator'@'localhost';"
sudo mariadb -e "FLUSH PRIVILEGES;"

# Configuring Galera cluster in /etc/mysql/my.cnf
sudo sed -i "s|#wsrep_on=ON|wsrep_on=ON|g" /etc/mysql/my.cnf
sudo sed -i "s|#wsrep_provider=*|wsrep_provider=/usr/lib/galera/libgalera_smm.so|g" /etc/mysql/my.cnf
sudo sed -i "s|#wsrep_cluster_address=*|wsrep_cluster_address="gcomm://$ip1,$ip2"|g" /etc/mysql/my.cnf
sudo sed -i "s|#binlog_format=row|binlog_format=row|g" /etc/mysql/my.cnf
sudo sed -i "s|#default_storage_engine=InnoDB|default_storage_engine=InnoDB|g" /etc/mysql/my.cnf
sudo sed -i "s|#innodb_autoinc_lock_mode=2|innodb_autoinc_lock_mode=2|g" /etc/mysql/my.cnf
sudo sed -i "s|#bind-address=0.0.0.0|bind-address=0.0.0.0|g" /etc/mysql/my.cnf

correctAnswer=false
while ! $correctAnswer; do
    # Ask if this is the firts node in the Galera cluster
    echo -n "Is this the first node in the Galera cluster? y/n: "
    read -r firstNode
    if [ "$firstNode" == "y" ] || [ "$firstNode" == "Y" ]; then
        sudo galera_new_cluster
        correctAnswer=true
    elif [ "$firstNode" == "n" ] || [ "$firstNode" == "N" ]; then
        sudo service mariadb restart
        correctAnswer=true
    else
        echo "Not a correct answer is given."
    fi
done

# Check if all nodes are running in the cluster
sudo mysql -u root -e "show status like 'wsrep_cluster%';"