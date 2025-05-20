# Script BIND9

<p align="center">
  <img src="https://img.shields.io/badge/Built%20with-Bash-1f425f?style=for-the-badge">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge">
  <img src="https://img.shields.io/badge/BIND9-DNS-blue?style=for-the-badge">
  <img src="https://img.shields.io/badge/OS-Debian%2FUbuntu-yellow?style=for-the-badge">
</p>

---
## About this script

This Bash script automates the **installation**, **configuration**, and **testing** of a **BIND9 DNS server** on Debian/Ubuntu systems. It sets up forward and reverse zones, adds DNS records, checks configurations, and restarts the service. Perfect for quick deployment in local or testing environments.

## 📦 Features

- Automatic installation of BIND9 and required dependencies
- Creation of forward and reverse zone files
- Addition of custom A and PTR records
- Configuration syntax check (`named-checkconf` / `named-checkzone`)
- BIND9 service restart and enablement
- Hosts file update (`/etc/hosts`) with main entry
- Quick testing with `dig`
  
## 📋 Requirements

- A fresh **Debian/Ubuntu** server
- Root privileges (`sudo`)
- Internet access

---

## 🚀 How to Use

1. Make the script executable:
   ```bash
   chmod +x install_bind9.sh
   ```

2. Run the script:
   ```bash
   sudo ./install_bind9.sh
   ```

3. Answer the interactive prompts:
   - Domain name
   - Main hostname
   - IP address
   - (Optional) Additional A and PTR records

---

## 📝 Example

```
➡️  Enter the domain name (e.g., mydomain.local): mynetwork.local
➡️  Enter the main hostname (e.g., dns-server): dns01
➡️  Enter the associated IP address (e.g., 192.168.1.10): 192.168.1.10
📌 Adding extra records (A + PTR) in network 192.168.1.x:
📝 [1] IP address: 192.168.1.20
➡️  FQDN: web.mynetwork.local
...
✅ BIND9 DNS server successfully configured!
```

## 📋 Operating System Compatibility

| **OS**      | **Version** | **Compatibility**   |
|-------------|-------------|---------------------|
| **Debian**  | 10          | ⚠️ Not tested       |
| **Debian**  | 11          | ✅ Compatible       |
| **Debian**  | 12          | ✅ Compatible       |
| **Ubuntu**  | 22.04       | ⚠️ Not tested       |
| **Ubuntu**  | 24.04       | ✅ Compatible       |
| **Ubuntu**  | 25.04       | ✅ Compatible       |

---

## 📁 Files Modified/Generated

- `/etc/bind/named.conf.options` (backup created)
- `/etc/bind/named.conf.local` (backup created)
- `/etc/bind/db.domain`
- `/etc/bind/db.reversezone`
- `/etc/hosts` (entry added if needed)

## 🔐 Security

This script does **not** implement DNS query restrictions or zone file access control. It is intended for **local** or **testing** use only. For production environments, additional security configurations are strongly recommended (ACLs, views, logging, etc.).

## 📜 License

This script is provided without warranty. You are free to modify, improve, or integrate it into other projects.
