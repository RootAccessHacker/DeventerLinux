#!/usr/bin/env bash

# Script variables
ip1="10.0.0.18"
ip2="10.0.0.19"

# Install mariadb packages
sudo apt update
sudo apt install haproxy -y

# Append rule to /etc/default/haproxy
checkConfig="ENABLED=1"
if ! grep -Fxq "$checkConfig" /etc/default/haproxy; then
    echo "ENABLED=1" | sudo tee -a /etc/default/haproxy >1 /dev/null
fi

# Backup default haproxt.cfg
haproxyCfg=/etc/haproxy/haproxy.cfg.bup
if [ ! -f "$haproxyCfg" ]; then
        sudo mv /etc/haproxy/haproxy.cfg $haproxyCfg
else
        written=false
        counter=1
        while ! $written; do
                if [ ! -f "$haproxyCfg-$counter" ]; then
                        sudo mv /etc/haproxy/haproxy.cfg "$haproxyCfg-$counter"
                        written=true
                else
                        ((counter+=1))
                fi
        done
fi

# Create haproxy.cfg
sudo -i <<-EOF
echo "global
        log /dev/log  local0
        log /dev/log  local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # Default ciphers to use on SSL-enabled listening sockets.
        # For more information, see ciphers(1SSL). This list is from:
        #  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
        # An alternative list with additional directives can be obtained from
        # https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=haproxy
        ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
        ssl-default-bind-options no-sslv3

defaults
        log  global
        mode  tcp
        option  tcplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http

frontend stats
        bind *:80
        mode http
        stats enable
        stats uri /stats
        stats refresh 5s
        stats auth administrator:Harderwijk1-2

frontend haproxy
        mode tcp
        default_backend mdb_servers

backend mdb_servers
        option tcplog
        balance leastconn
        server mdb1 $ip1:3306 check
        server mdb2 $ip2:3306 check
" | sudo tee /etc/haproxy/haproxy.cfg >1 /dev/null
EOF

# Enable haproxy
sudo systemctl enable --now haproxy
sudo systemctl restart haproxy