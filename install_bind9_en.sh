#!/bin/bash

###############################################################################
# Script for automatic installation and configuration of BIND9
# - Creates forward and reverse zone files
# - Adds custom DNS records
# - Checks configuration and restarts BIND9
# - Adds main entry to /etc/hosts
# Author: Shaikos
# Date: 20/05/2025
###############################################################################

# === Check for root privileges ===
if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root."
  exit 1
fi

# === Ensure script is executed with bash ===
if [ -z "$BASH_VERSION" ]; then
  echo "❌ This script must be run with bash, not sh."
  exit 1
fi

# === Gather user input ===
read -rp "➡️  Enter the domain name (e.g., mydomain.local): " DOMAIN
read -rp "➡️  Enter the main hostname (e.g., srv-dns): " HOSTNAME
read -rp "➡️  Enter the associated IP address (e.g., 192.168.0.10): " IP

# === Automatically deduce reverse zone ===
IFS='.' read -r o1 o2 o3 o4 <<< "$IP"
REVERSE_ZONE="$o3.$o2.$o1.in-addr.arpa"
REVERSE_ZONE_SHORT="$o3.$o2.$o1"
SUBNET="$o1.$o2.$o3"
echo "ℹ️  Automatically deduced reverse zone: $REVERSE_ZONE"

ZONE_FILE="/etc/bind/db.$DOMAIN"
REVERSE_ZONE_FILE="/etc/bind/db.$REVERSE_ZONE_SHORT"
TTL="604800"

echo "🛠 Installing BIND9 and setting up DNS for domain $DOMAIN..."

# === Update and install required packages ===
apt update && apt upgrade -y
apt install -y bind9 bind9utils bind9-doc

# === Backup existing configuration files ===
cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak

# === Global BIND9 configuration ===
cat > /etc/bind/named.conf.options <<EOF
options {
  directory "/var/cache/bind";
  recursion yes;
  allow-query { any; };
  forwarders {
    8.8.8.8;
    8.8.4.4;
  };
  dnssec-validation auto;
  listen-on { any; };
};
EOF

# === Declare DNS zones (forward and reverse) ===
cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN" {
  type master;
  file "$ZONE_FILE";
};

zone "$REVERSE_ZONE" {
  type master;
  file "$REVERSE_ZONE_FILE";
};
EOF

# === Create forward zone file ===
cat > "$ZONE_FILE" <<EOF
\$TTL $TTL
@   IN  SOA $HOSTNAME.$DOMAIN. admin.$DOMAIN. (
          2         ; Serial
     $TTL         ; Refresh
      86400       ; Retry
    2419200       ; Expire
     604800 )     ; Negative Cache TTL
;
@       IN  NS    $HOSTNAME.$DOMAIN.
$HOSTNAME   IN  A     $IP
EOF

# === Create reverse zone file ===
LAST_OCTET=$(echo $IP | awk -F. '{print $4}')
cat > "$REVERSE_ZONE_FILE" <<EOF
\$TTL $TTL
@   IN  SOA $HOSTNAME.$DOMAIN. admin.$DOMAIN. (
          2         ; Serial
     $TTL         ; Refresh
      86400       ; Retry
    2419200       ; Expire
     604800 )     ; Negative Cache TTL
;
@       IN  NS    $HOSTNAME.$DOMAIN.
$LAST_OCTET   IN  PTR   $HOSTNAME.$DOMAIN.
EOF

# === Add custom A and PTR records ===
echo "📌 Adding additional records (A + PTR) in network $SUBNET.x:"
for i in 1 2 3; do
  read -rp "📝 [$i] IP address (leave empty to skip): " EXTRA_IP
  [ -z "$EXTRA_IP" ] && continue

  EXTRA_SUBNET=$(echo "$EXTRA_IP" | awk -F. '{print $1"."$2"."$3}')
  if [[ "$EXTRA_SUBNET" != "$SUBNET" ]]; then
    echo "⚠️  IP address $EXTRA_IP does not belong to subnet $SUBNET.x → skipped."
    continue
  fi

  read -rp "➡️  Full name (FQDN, e.g., web.$DOMAIN): " EXTRA_NAME
  EXTRA_HOST=$(echo "$EXTRA_NAME" | cut -d. -f1)
  LAST_BYTE=$(echo "$EXTRA_IP" | awk -F. '{print $4}')

  echo "$EXTRA_HOST   IN  A     $EXTRA_IP" >> "$ZONE_FILE"
  echo "$LAST_BYTE   IN  PTR   $EXTRA_NAME." >> "$REVERSE_ZONE_FILE"
  echo "✅ Record $EXTRA_HOST.$DOMAIN added."
done

# === BIND9 configuration check ===
echo "🔍 Checking BIND configuration..."
named-checkconf || { echo "❌ Error in named.conf"; exit 1; }
named-checkzone "$DOMAIN" "$ZONE_FILE" || { echo "❌ Error in $ZONE_FILE"; exit 1; }
named-checkzone "$REVERSE_ZONE" "$REVERSE_ZONE_FILE" || { echo "❌ Error in $REVERSE_ZONE_FILE"; exit 1; }

# === Restart and enable BIND9 ===
systemctl restart bind9
systemctl enable bind9

# === Automatically add entry to /etc/hosts ===
FQDN="$HOSTNAME.$DOMAIN"
if ! grep -q "$FQDN" /etc/hosts; then
  echo "$IP    $FQDN $HOSTNAME" >> /etc/hosts
  echo "✅ Added $FQDN to /etc/hosts"
else
  echo "ℹ️  $FQDN is already present in /etc/hosts"
fi

# === Test DNS resolution with dig ===
echo "🔎 Testing DNS resolution with dig:"
dig @"$IP" "$FQDN" +short

echo
echo "✅ BIND9 DNS server successfully configured!"
echo "➡️  Domain: $DOMAIN"
echo "➡️  Main host: $FQDN"
echo "➡️  IP: $IP"
echo "➡️  Reverse zone: $REVERSE_ZONE"
