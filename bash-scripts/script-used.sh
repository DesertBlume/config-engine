#!/bin/bash

# Program Name: apache_conf_lab6.sh
# Purpose: Automate CST8246 Lab 6 (Apache, DNS, SSL, Firewall)
# Author: YOUR NAME 0405XXXXX -XXX
# Date: July 10th, 2025

# ================================
# Variables
# ================================
SRV_IP=172.16.30.48
NS2_IP=172.16.31.48
ALIAS_IP=172.16.32.48
DOMAIN_EX=example48.lab
DOMAIN_SITE=site48.lab

# ================================
# Install packages
# ================================
echo "[+] Installing Apache, BIND, and SSL tools..."
sudo yum install -y httpd bind bind-utils openssl mod_ssl
sudo yum update -y httpd

# ================================
# Start and enable Apache
# ================================
sudo systemctl start httpd
sudo systemctl enable httpd
httpd -v

# ================================
# Disable default ssl.conf to avoid localhost.crt problem
# ================================
sudo mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.disabled || true

# ================================
# Backup httpd.conf
# ================================
sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bk

# ================================
# Verify Apache syntax
# ================================
httpd -t

# ================================
# Create base index.html
# ================================
cat <<EOF | sudo tee /var/www/html/index.html > /dev/null
<head><Title>${DOMAIN_EX}</Title></head>
<H1>Host:${DOMAIN_EX} [${SRV_IP}:80]</H1>
EOF

# ================================
# Create vhost directories
# ================================
sudo mkdir -p /var/www/vhosts/www.${DOMAIN_EX}/html /var/www/vhosts/www.${DOMAIN_EX}/log
sudo mkdir -p /var/www/vhosts/www.${DOMAIN_SITE}/html /var/www/vhosts/www.${DOMAIN_SITE}/log
sudo mkdir -p /var/www/vhosts/secure.${DOMAIN_EX}/html /var/www/vhosts/secure.${DOMAIN_EX}/log

# ================================
# TLS dirs & permissions
# ================================
sudo mkdir -p /etc/httpd/tls/{key,cert}
sudo chmod 700 /etc/httpd/tls/key
sudo chmod 755 /etc/httpd/tls/cert

# ================================
# Create self-signed cert & key
# ================================
sudo openssl req -x509 -newkey rsa:2048 -days 365 -nodes \
-keyout /etc/httpd/tls/key/${DOMAIN_EX}.key \
-out /etc/httpd/tls/cert/${DOMAIN_EX}.cert \
-subj "/C=CA/ST=ON/L=Ottawa/O=College/OU=IT/CN=secure.${DOMAIN_EX}"

sudo chmod 600 /etc/httpd/tls/key/${DOMAIN_EX}.key
sudo chmod 644 /etc/httpd/tls/cert/${DOMAIN_EX}.cert

# Verify cert details
sudo openssl x509 -in /etc/httpd/tls/cert/${DOMAIN_EX}.cert -noout -text
sudo openssl x509 -noout -modulus -in /etc/httpd/tls/cert/${DOMAIN_EX}.cert | md5sum
sudo openssl rsa -noout -modulus -in /etc/httpd/tls/key/${DOMAIN_EX}.key | md5sum

# ================================
# Copy index.html for each site
# ================================
sudo cp /var/www/html/index.html /var/www/vhosts/www.${DOMAIN_EX}/html
sudo cp /var/www/html/index.html /var/www/vhosts/www.${DOMAIN_SITE}/html
sudo cp /var/www/html/index.html /var/www/vhosts/secure.${DOMAIN_EX}/html

# ================================
# Map site → IP:PORT and update index.html
# ================================
declare -A site_info=(
  ["www.${DOMAIN_EX}"]="${SRV_IP}:80"
  ["www.${DOMAIN_SITE}"]="${SRV_IP}:80"
  ["secure.${DOMAIN_EX}"]="${ALIAS_IP}:443"
)

base_path="/var/www/vhosts"

for site in "${!site_info[@]}"; do
  dir="$base_path/$site/html"
  ip_port="${site_info[$site]}"
  file="$dir/index.html"

  if [[ -f "$file" ]]; then
    sed -i -E "s|<Title>.*</Title>|<Title>$site</Title>|g" "$file"
    sed -i -E "s|<H1>Host:.*\[.*\]</H1>|<H1>Host:$site [$ip_port]</H1>|g" "$file"
    echo "Updated $file for $site"
  else
    echo "File not found: $file"
  fi
done

# ================================
# Create VirtualHosts in httpd.conf
# ================================
cat <<EOF | sudo tee -a /etc/httpd/conf/httpd.conf > /dev/null
<VirtualHost ${SRV_IP}:80>
    ServerName www.${DOMAIN_EX}
    DocumentRoot /var/www/vhosts/www.${DOMAIN_EX}/html/
    ErrorLog /var/www/vhosts/www.${DOMAIN_EX}/log/error.log
</VirtualHost>

<VirtualHost ${SRV_IP}:80>
    ServerName www.${DOMAIN_SITE}
    DocumentRoot /var/www/vhosts/www.${DOMAIN_SITE}/html/
    ErrorLog /var/www/vhosts/www.${DOMAIN_SITE}/log/error.log
</VirtualHost>

<VirtualHost ${ALIAS_IP}:443>
    ServerName secure.${DOMAIN_EX}
    DocumentRoot /var/www/vhosts/secure.${DOMAIN_EX}/html/
    ErrorLog /var/www/vhosts/secure.${DOMAIN_EX}/log/error.log
    SSLCertificateFile /etc/httpd/tls/cert/${DOMAIN_EX}.cert
    SSLCertificateKeyFile /etc/httpd/tls/key/${DOMAIN_EX}.key
    SSLEngine On
</VirtualHost>
EOF

# ================================
# Add site zone to named.conf
# ================================
sudo sed -i "/include \"\/etc\/named.rfc1912.zones\"/i \
zone \"${DOMAIN_SITE}\" IN {\
\n\ttype master;\
\n\tfile \"fwd.${DOMAIN_SITE}\";\
\n\tallow-update { none; };\
\n};\n" /etc/named.conf

# ================================
# Create or overwrite fwd.example48.lab
# ================================
cat <<EOF | sudo tee /var/named/fwd.${DOMAIN_EX} > /dev/null
\$TTL 86400
\$ORIGIN ${DOMAIN_EX}.

@       IN SOA ns1.${DOMAIN_EX}. dnsadmin.${DOMAIN_EX}. (
                20250710
                30
                14400
                604800
                86400 )

        IN NS ns1.${DOMAIN_EX}.
        IN NS ns2.${DOMAIN_EX}.

ns1     IN A    ${SRV_IP}
ns2     IN A    ${NS2_IP}
ftp     IN A    ${ALIAS_IP}
www     IN A    ${SRV_IP}
secure  IN A    ${ALIAS_IP}
EOF

# ================================
# Create or overwrite fwd.site48.lab
# ================================
cat <<EOF | sudo tee /var/named/fwd.${DOMAIN_SITE} > /dev/null
\$TTL 86400
\$ORIGIN ${DOMAIN_SITE}.
@	IN	SOA	${DOMAIN_SITE}.	dnsadmin.${DOMAIN_SITE}. (
					20250710
					1D
					1H
					1W
					3H )
@	IN	NS	ns1.${DOMAIN_EX}.
ns1	IN	A	${SRV_IP}
www	IN	A	${SRV_IP}
EOF

# ================================
# Create or overwrite named.16.172
# ================================
cat <<EOF | sudo tee /var/named/named.16.172 > /dev/null
\$TTL 86400
\$ORIGIN 16.172.in-addr.arpa.

@       IN SOA ns1.${DOMAIN_EX}. dnsadmin.${DOMAIN_EX}. (
            20250710
            28800
            14400
            604800
            86400 )

        IN NS   ns1.${DOMAIN_EX}.
        IN NS   ns2.${DOMAIN_EX}.

48.30   IN PTR ns1.${DOMAIN_EX}.
48.30   IN PTR www.${DOMAIN_EX}.
48.30   IN PTR www.${DOMAIN_SITE}.
48.31   IN PTR ns2.${DOMAIN_EX}.
48.32   IN PTR ftp.${DOMAIN_EX}.
48.32   IN PTR secure.${DOMAIN_EX}.
EOF

# ================================
# Validate BIND config
# ================================
sudo named-checkconf

# ================================
# Restart services
# ================================
sudo systemctl restart named
sudo systemctl restart httpd

# ================================
# Run dig tests
# ================================
dig www.${DOMAIN_SITE}
dig www.${DOMAIN_EX}
dig secure.${DOMAIN_EX}

# ================================
# Configure Firewall
# ================================
sudo iptables -F
sudo iptables -A INPUT -s 172.16.31.0/24 -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -s 172.16.31.0/24 -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -s 172.16.30.0/24 -p tcp --dport 80 -j REJECT
sudo iptables -A INPUT -s 172.16.30.0/24 -p tcp --dport 443 -j REJECT
sudo iptables -A INPUT -s 172.16.32.0/24 -p tcp --dport 80 -j REJECT

# ================================
# Test with curl
# ================================
curl --interface ${SRV_IP} www.${DOMAIN_EX}
curl --interface ${SRV_IP} www.${DOMAIN_SITE}
curl --interface ${ALIAS_IP} secure.${DOMAIN_EX}

echo "[+] Lab 6 automation complete!"

