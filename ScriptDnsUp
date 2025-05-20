#!/bin/bash

###############################################################################
# Script d'ajout automatique d'enregistrements DNS (A et PTR) dans BIND9
# Auteur : Shaikos
# Date : 20/05/2025
###############################################################################

# === Vérification des privilèges root ===
if [ "$EUID" -ne 0 ]; then
  echo "❌ Ce script doit être exécuté en root."
  exit 1
fi

# === Récupération des domaines directs (exclusion des zones inverses) ===
mapfile -t zones < <(
  grep '^zone' /etc/bind/named.conf.local \
    | awk '{print $2}' \
    | tr -d '"' \
    | grep -v '\.in-addr\.arpa'
)

if [ ${#zones[@]} -eq 0 ]; then
  echo "❌ Aucun domaine direct trouvé dans /etc/bind/named.conf.local"
  exit 1
fi

echo "🌐 Domaines directs disponibles :"
select DOMAIN in "${zones[@]}"; do
  if [[ -n "$DOMAIN" ]]; then
    echo "✅ Domaine sélectionné : $DOMAIN"
    break
  else
    echo "❌ Choix invalide."
  fi
done

# === Extraction du chemin vers le fichier de zone ===
ZONE_FILE=$(awk "/zone \"$DOMAIN\"/,/};/" /etc/bind/named.conf.local \
            | grep 'file' \
            | head -1 \
            | awk '{print $2}' \
            | tr -d '";')

if [[ -z "$ZONE_FILE" ]]; then
  echo "❌ Fichier de zone introuvable pour $DOMAIN"
  exit 1
fi
echo "ℹ Fichier de zone direct : $ZONE_FILE"

if [[ ! -f "$ZONE_FILE" ]]; then
  echo "❌ Le fichier $ZONE_FILE n'existe pas."
  exit 1
fi

# === Extraction du hostname principal ===
HOSTNAME=$(grep -m1 -Po '^\s*\K[^ \t]+' "$ZONE_FILE")
if [[ -z "$HOSTNAME" ]]; then
  read -rp "➡ Nom d'hôte principal (ex: srv-dns) : " HOSTNAME
else
  echo "ℹ Hostname principal détecté : $HOSTNAME"
fi

# === Extraction de l'IP du serveur DNS (A record) ===
DNS_IP=$(grep -m1 -Po "^\s*$HOSTNAME\s+IN\s+A\s+\K[\d\.]+" "$ZONE_FILE")
if [[ -z "$DNS_IP" ]]; then
  read -rp "➡ Adresse IP du serveur DNS (ex: 192.168.0.10) : " DNS_IP
else
  echo "ℹ Adresse IP détectée pour $HOSTNAME : $DNS_IP"
fi

# === Déduction et extraction de la zone inverse ===
# On en déduit le préfixe et on recherche le fichier associé
IFS='.' read -r o1 o2 o3 o4 <<< "$DNS_IP"
REVERSE_ZONE_PREFIX="$o3.$o2.$o1"
REVERSE_ZONE="${REVERSE_ZONE_PREFIX}.in-addr.arpa"

# On récupère le chemin du fichier de zone inverse
REVERSE_ZONE_FILE=$(awk "/zone \"$REVERSE_ZONE\"/,/};/" /etc/bind/named.conf.local \
                    | grep 'file' \
                    | head -1 \
                    | awk '{print $2}' \
                    | tr -d '";')

if [[ -z "$REVERSE_ZONE_FILE" ]]; then
  echo "❌ Fichier de zone inverse introuvable pour $REVERSE_ZONE"
  exit 1
fi
echo "ℹ Fichier de zone inverse : $REVERSE_ZONE_FILE"

if [[ ! -f "$REVERSE_ZONE_FILE" ]]; then
  echo "❌ Le fichier $REVERSE_ZONE_FILE n'existe pas."
  exit 1
fi

# === Préparation du sous-réseau pour validation ===
SUBNET="$o1.$o2.$o3"

echo
echo "=== Ajout des enregistrements pour le domaine $DOMAIN ==="

# === Boucle interactive d'ajout d'enregistrements ===
LAST_ADDED_FQDN=""
while true; do
  echo -e "\n➕ Ajout d’un enregistrement (laisser vide pour quitter)"
  read -rp "📝 Adresse IP (ex: $SUBNET.20) : " EXTRA_IP
  [[ -z "$EXTRA_IP" ]] && break

  # Validation du sous-réseau
  EXTRA_SUBNET=$(echo "$EXTRA_IP" | awk -F. '{print $1"."$2"."$3}')
  if [[ "$EXTRA_SUBNET" != "$SUBNET" ]]; then
    echo "⚠ L'adresse IP $EXTRA_IP n'est pas dans le sous-réseau $SUBNET.x → ignorée."
    continue
  fi

  read -rp "➡ Nom complet (FQDN, ex: web.$DOMAIN) : " EXTRA_FQDN
  EXTRA_HOST=${EXTRA_FQDN%%.$DOMAIN}   # retire .DOMAIN
  LAST_BYTE=${EXTRA_IP##*.}

  # Vérification des doublons A record
  if grep -qE "^[[:space:]]*${EXTRA_HOST}[[:space:]]+IN[[:space:]]+A[[:space:]]+${EXTRA_IP}" "$ZONE_FILE"; then
    echo "ℹ Enregistrement A pour $EXTRA_FQDN ($EXTRA_IP) existe déjà → ignoré."
    continue
  fi

  # Vérification des doublons PTR
  if grep -qE "^[[:space:]]*${LAST_BYTE}[[:space:]]+IN[[:space:]]+PTR[[:space:]]+${EXTRA_FQDN}\." "$REVERSE_ZONE_FILE"; then
    echo "ℹ PTR pour $EXTRA_FQDN existe déjà → ignoré."
    continue
  fi

  # Ajout dans les fichiers
  echo -e "${EXTRA_HOST}\tIN\tA\t${EXTRA_IP}" >> "$ZONE_FILE"
  echo -e "${LAST_BYTE}\tIN\tPTR\t${EXTRA_FQDN}." >> "$REVERSE_ZONE_FILE"
  echo "✔ Enregistrement $EXTRA_FQDN ajouté."
  LAST_ADDED_FQDN="$EXTRA_FQDN"
done

# === Vérification de la configuration BIND ===
echo
echo "🔍 Vérification de la configuration BIND..."
named-checkconf || { echo "❌ Erreur de configuration générale."; exit 1; }
named-checkzone "$DOMAIN" "$ZONE_FILE"  || { echo "❌ Erreur dans $ZONE_FILE"; exit 1; }
named-checkzone "$REVERSE_ZONE" "$REVERSE_ZONE_FILE" || { echo "❌ Erreur dans $REVERSE_ZONE_FILE"; exit 1; }

# === Redémarrage de BIND9 ===
systemctl restart bind9
echo "✔ BIND9 redémarré."
echo
echo "✔ Tous les enregistrements ont été traités."
