# Script d'installation et de configuration automatique de BIND9

Ce script Bash permet d’installer, configurer et tester automatiquement un serveur DNS **BIND9** sur un système Linux (Debian/Ubuntu). Il crée les zones directe et inverse, ajoute les enregistrements DNS, vérifie la configuration et redémarre le service. Très utile pour un déploiement rapide dans un environnement local ou de test.

## 📦 Fonctionnalités

- Installation automatique de BIND9 et des dépendances
- Création des fichiers de zone directe et inverse
- Ajout d'enregistrements DNS personnalisés (A et PTR)
- Vérification de la configuration (`named-checkconf` / `named-checkzone`)
- Redémarrage et activation du service `bind9`
- Ajout de l’entrée principale dans `/etc/hosts`
- Test rapide avec `dig`

## 🧑‍💻 Auteur

- **Nom** : Shaikos  
- **Date** : 20/05/2025

## ⚠️ Prérequis

- Exécution en tant que **root**
- Environnement Debian/Ubuntu (apt)
- Script lancé avec **bash**

## 🚀 Utilisation

1. Rends le script exécutable :
   ```bash
   chmod +x install_bind9.sh
   ```

2. Exécute le script :
   ```bash
   sudo ./install_bind9.sh
   ```

3. Réponds aux différentes questions interactives :
   - Nom de domaine
   - Nom d’hôte principal
   - Adresse IP
   - (optionnel) Ajout d’enregistrements A et PTR supplémentaires

## 📝 Exemple

```
➡️  Entrez le nom de domaine (ex: mondomaine.local) : monreseau.local
➡️  Entrez le nom d'hôte principal (ex: srv-dns) : dns01
➡️  Entrez l'adresse IP associée (ex: 192.168.1.10) : 192.168.1.10
📌 Ajout d’enregistrements supplémentaires (A + PTR) dans le réseau 192.168.1.x :
📝 [1] Adresse IP : 192.168.1.20
➡️  Nom complet : web.monreseau.local
...
✅ Serveur DNS BIND9 configuré avec succès !
```

## 🔍 Vérifications automatiques

- Syntaxe des fichiers de configuration avec `named-checkconf`
- Validation des zones DNS avec `named-checkzone`
- Test de résolution DNS avec `dig`

## 📁 Fichiers modifiés/générés

- `/etc/bind/named.conf.options` (sauvegarde faite)
- `/etc/bind/named.conf.local` (sauvegarde faite)
- `/etc/bind/db.nomdomaine`
- `/etc/bind/db.zoneinverse`
- `/etc/hosts` (ajout si nécessaire)

## 🔐 Sécurité

Ce script ne configure pas de restrictions sur les requêtes DNS ou sur l'accès aux fichiers de zone. Il est conçu pour un usage **local** ou **en environnement de test**. Pour une mise en production, des ajustements supplémentaires sont nécessaires (ACL, vues, journalisation, etc.).

## 📜 Licence

Ce script est distribué sans garantie. Tu peux le modifier, l'améliorer ou l'intégrer dans d'autres projets.
