#!/usr/bin/env bash

# Script variables
ip1="10.0.0.18"
ip2="10.0.0.19"
ip3="10.100.0.2"
dbAdmin="administrator"
dbAdminPasswd="Harderwijk1-2"

# Install mariadb packages
sudo apt update
sudo apt install software-properties-common -y
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mariadb.mirror.liquidtelecom.com/repo/10.6/ubuntu focal main'
sudo apt update
sudo apt install mariadb-server mariadb-client -y

# Run mariadb secure installation
echo
echo "Give as answers for the mysql secure installation the following answers:"
echo "Empty password (just press enter)"
echo "n"
echo "n"
echo "y"
echo "y"
echo "y"
echo "y"
sudo mysql_secure_installation

# Create mariadb database for moodle
sudo mariadb -e "CREATE DATABASE moodledb;"
sudo mariadb -e "CREATE USER '$dbAdmin'@'localhost' IDENTIFIED BY '$dbAdminPasswd';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON *.* TO '$dbAdmin'@'localhost';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON *.* TO '$dbAdmin'@'10.0.0.17';"
sudo mariadb -e "FLUSH PRIVILEGES;"

# Change mariadb bind address
sudo sed -i "s|bind-address =*|bind-address = 0.0.0.0|g" /etc/mysql/mariadb.conf.d/50-server.cnf

# Append Galera cluster config to 60-galera.cnf
sudo -i <<-EOF
echo "
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://$ip1,$ip2,$ip3"
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0
" | sudo tee -a /etc/mysql/mariadb.conf.d/60-galera.cnf >1 /dev/null
EOF

correctAnswer=false
while ! $correctAnswer; do
    # Ask if this is the first node in the Galera cluster
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

# Enable mariadb server and check if all nodes are running in the cluster
sudo systemctl enable --now mariadb
sudo mysql -u root -e "show status like 'wsrep_cluster%';"