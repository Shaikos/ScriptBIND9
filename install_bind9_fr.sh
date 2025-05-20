#!/bin/bash

###############################################################################
# Script d'installation et de configuration automatique de BIND9
# - Crée les fichiers de zone directe et inverse
# - Ajoute des enregistrements personnalisés
# - Vérifie la configuration et redémarre BIND9
# - Ajoute l'entrée principale dans /etc/hosts
# Auteur : Shaikos
# Date : 20/05/2025
###############################################################################

# === Vérification des privilèges root ===
if [ "$EUID" -ne 0 ]; then
  echo "❌ Ce script doit être exécuté en tant que root."
  exit 1
fi

# === Vérification si le script est exécuté avec bash ===
if [ -z "$BASH_VERSION" ]; then
  echo "❌ Ce script doit être exécuté avec bash, pas sh."
  exit 1
fi

# === Collecte des informations utilisateur ===
read -rp "➡️  Entrez le nom de domaine (ex: mondomaine.local) : " DOMAIN
read -rp "➡️  Entrez le nom d'hôte principal (ex: srv-dns) : " HOSTNAME
read -rp "➡️  Entrez l'adresse IP associée (ex: 192.168.0.10) : " IP

# === Déduction automatique de la zone inverse ===
IFS='.' read -r o1 o2 o3 o4 <<< "$IP"
REVERSE_ZONE="$o3.$o2.$o1.in-addr.arpa"
REVERSE_ZONE_SHORT="$o3.$o2.$o1"
SUBNET="$o1.$o2.$o3"
echo "ℹ️  Zone inverse déduite automatiquement : $REVERSE_ZONE"

ZONE_FILE="/etc/bind/db.$DOMAIN"
REVERSE_ZONE_FILE="/etc/bind/db.$REVERSE_ZONE_SHORT"
TTL="604800"

echo "🛠 Installation de BIND9 et configuration DNS pour le domaine $DOMAIN..."

# === Mise à jour et installation des paquets nécessaires ===
apt update && apt upgrade -y
apt install -y bind9 bind9utils bind9-doc

# === Sauvegarde des fichiers de configuration existants ===
cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak

# === Configuration globale de BIND9 ===
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

# === Déclaration des zones DNS (directe et inverse) ===
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

# === Création du fichier de zone directe ===
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

# === Création du fichier de zone inverse ===
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

# === Ajout d'enregistrements personnalisés (A et PTR) ===
echo "📌 Ajout d’enregistrements supplémentaires (A + PTR) dans le réseau $SUBNET.x"
for i in 1 2 3; do
  read -rp "📝 [$i] Adresse IP (laisser vide pour ignorer) : " EXTRA_IP
  [ -z "$EXTRA_IP" ] && continue

  EXTRA_SUBNET=$(echo "$EXTRA_IP" | awk -F. '{print $1"."$2"."$3}')
  if [[ "$EXTRA_SUBNET" != "$SUBNET" ]]; then
    echo "⚠️  L'adresse IP $EXTRA_IP n'appartient pas au sous-réseau $SUBNET.x → ignorée."
    continue
  fi

  read -rp "➡️  Nom complet (FQDN, ex: web.$DOMAIN) : " EXTRA_NAME
  EXTRA_HOST=$(echo "$EXTRA_NAME" | cut -d. -f1)
  LAST_BYTE=$(echo "$EXTRA_IP" | awk -F. '{print $4}')

  echo "$EXTRA_HOST   IN  A     $EXTRA_IP" >> "$ZONE_FILE"
  echo "$LAST_BYTE   IN  PTR   $EXTRA_NAME." >> "$REVERSE_ZONE_FILE"
  echo "✅ Enregistrement $EXTRA_HOST.$DOMAIN ajouté."
done

# === Vérification de la configuration BIND9 ===
echo "🔍 Vérification de la configuration BIND..."
named-checkconf || { echo "❌ Erreur dans named.conf"; exit 1; }
named-checkzone "$DOMAIN" "$ZONE_FILE" || { echo "❌ Erreur dans $ZONE_FILE"; exit 1; }
named-checkzone "$REVERSE_ZONE" "$REVERSE_ZONE_FILE" || { echo "❌ Erreur dans $REVERSE_ZONE_FILE"; exit 1; }

# === Redémarrage et activation de BIND9 ===
systemctl restart bind9
systemctl enable bind9

# === Ajout automatique à /etc/hosts ===
FQDN="$HOSTNAME.$DOMAIN"
if ! grep -q "$FQDN" /etc/hosts; then
  echo "$IP    $FQDN $HOSTNAME" >> /etc/hosts
  echo "✅ Ajout de $FQDN à /etc/hosts"
else
  echo "ℹ️  $FQDN est déjà présent dans /etc/hosts"
fi

# === Test de résolution DNS avec dig ===
echo "🔎 Test de résolution DNS avec dig :"
dig @"$IP" "$FQDN" +short

echo
echo "✅ Serveur DNS BIND9 configuré avec succès !"
echo "➡️  Domaine : $DOMAIN"
echo "➡️  Hôte principal : $FQDN"
echo "➡️  IP : $IP"
echo "➡️  Zone inverse : $REVERSE_ZONE"
