#!/bin/bash

###############################################################################
# Script for automatic addition of DNS records (A and PTR) in BIND9
# Author: Shaikos
# Date: 20/05/2025
###############################################################################

# === Root privilege check ===
if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root."
  exit 1
fi

# === Retrieve direct zones (excluding reverse zones) ===
mapfile -t zones < <(
  grep '^zone' /etc/bind/named.conf.local \
    | awk '{print $2}' \
    | tr -d '"' \
    | grep -v '\.in-addr\.arpa'
)

if [ ${#zones[@]} -eq 0 ]; then
  echo "❌ No direct zones found in /etc/bind/named.conf.local"
  exit 1
fi

echo "🌐 Available direct zones:"
select DOMAIN in "${zones[@]}"; do
  if [[ -n "$DOMAIN" ]]; then
    echo "✅ Selected domain: $DOMAIN"
    break
  else
    echo "❌ Invalid choice."
  fi
done

# === Extract path to zone file ===
ZONE_FILE=$(awk "/zone \"$DOMAIN\"/,/};/" /etc/bind/named.conf.local \
            | grep 'file' \
            | head -1 \
            | awk '{print $2}' \
            | tr -d '";')

if [[ -z "$ZONE_FILE" ]]; then
  echo "❌ Zone file not found for $DOMAIN"
  exit 1
fi
echo "ℹ Direct zone file: $ZONE_FILE"

if [[ ! -f "$ZONE_FILE" ]]; then
  echo "❌ File $ZONE_FILE does not exist."
  exit 1
fi

# === Extract main hostname ===
HOSTNAME=$(grep -m1 -Po '^\s*\K[^ \t]+' "$ZONE_FILE")
if [[ -z "$HOSTNAME" ]]; then
  read -rp "➡ Main hostname (e.g., srv-dns): " HOSTNAME
else
  echo "ℹ Detected main hostname: $HOSTNAME"
fi

# === Extract DNS server IP (A record) ===
DNS_IP=$(grep -m1 -Po "^\s*$HOSTNAME\s+IN\s+A\s+\K[\d\.]+" "$ZONE_FILE")
if [[ -z "$DNS_IP" ]]; then
  read -rp "➡ DNS server IP address (e.g., 192.168.0.10): " DNS_IP
else
  echo "ℹ Detected IP address for $HOSTNAME: $DNS_IP"
fi

# === Deduce and extract reverse zone ===
IFS='.' read -r o1 o2 o3 o4 <<< "$DNS_IP"
REVERSE_ZONE_PREFIX="$o3.$o2.$o1"
REVERSE_ZONE="${REVERSE_ZONE_PREFIX}.in-addr.arpa"

# Get the reverse zone file path
REVERSE_ZONE_FILE=$(awk "/zone \"$REVERSE_ZONE\"/,/};/" /etc/bind/named.conf.local \
                    | grep 'file' \
                    | head -1 \
                    | awk '{print $2}' \
                    | tr -d '";')

if [[ -z "$REVERSE_ZONE_FILE" ]]; then
  echo "❌ Reverse zone file not found for $REVERSE_ZONE"
  exit 1
fi
echo "ℹ Reverse zone file: $REVERSE_ZONE_FILE"

if [[ ! -f "$REVERSE_ZONE_FILE" ]]; then
  echo "❌ File $REVERSE_ZONE_FILE does not exist."
  exit 1
fi

# === Prepare subnet for validation ===
SUBNET="$o1.$o2.$o3"

echo
echo "=== Adding records for domain $DOMAIN ==="

# === Interactive loop for adding records ===
LAST_ADDED_FQDN=""
while true; do
  echo -e "\n➕ Add a record (leave blank to quit)"
  read -rp "📝 IP address (e.g., $SUBNET.20): " EXTRA_IP
  [[ -z "$EXTRA_IP" ]] && break

  # Subnet validation
  EXTRA_SUBNET=$(echo "$EXTRA_IP" | awk -F. '{print $1"."$2"."$3}')
  if [[ "$EXTRA_SUBNET" != "$SUBNET" ]]; then
    echo "⚠ IP address $EXTRA_IP is not in subnet $SUBNET.x → ignored."
    continue
  fi

  read -rp "➡ Full name (FQDN, e.g., web.$DOMAIN): " EXTRA_FQDN
  EXTRA_HOST=${EXTRA_FQDN%%.$DOMAIN}   # remove .DOMAIN
  LAST_BYTE=${EXTRA_IP##*.}

  # Check for existing A record
  if grep -qE "^[[:space:]]*${EXTRA_HOST}[[:space:]]+IN[[:space:]]+A[[:space:]]+${EXTRA_IP}" "$ZONE_FILE"; then
    echo "ℹ A record for $EXTRA_FQDN ($EXTRA_IP) already exists → ignored."
    continue
  fi

  # Check for existing PTR
  if grep -qE "^[[:space:]]*${LAST_BYTE}[[:space:]]+IN[[:space:]]+PTR[[:space:]]+${EXTRA_FQDN}\." "$REVERSE_ZONE_FILE"; then
    echo "ℹ PTR for $EXTRA_FQDN already exists → ignored."
    continue
  fi

  # Append records to files
  echo -e "${EXTRA_HOST}\tIN\tA\t${EXTRA_IP}" >> "$ZONE_FILE"
  echo -e "${LAST_BYTE}\tIN\tPTR\t${EXTRA_FQDN}." >> "$REVERSE_ZONE_FILE"
  echo "✔ Record $EXTRA_FQDN added."
  LAST_ADDED_FQDN="$EXTRA_FQDN"
done

# === BIND configuration check ===
echo
echo "🔍 Checking BIND configuration..."
named-checkconf || { echo "❌ General configuration error."; exit 1; }
named-checkzone "$DOMAIN" "$ZONE_FILE"  || { echo "❌ Error in $ZONE_FILE"; exit 1; }
named-checkzone "$REVERSE_ZONE" "$REVERSE_ZONE_FILE" || { echo "❌ Error in $REVERSE_ZONE_FILE"; exit 1; }

# === Restart BIND9 ===
systemctl restart bind9
echo "✔ BIND9 restarted."
echo
echo "✔ All records have been processed."
