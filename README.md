# Script BIND9

<p align="center">
  <img src="https://img.shields.io/badge/Built%20with-Bash-1f425f?style=for-the-badge">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge">
  <img src="https://img.shields.io/badge/BIND9-DNS-blue?style=for-the-badge">
  <img src="https://img.shields.io/badge/OS-Debian%2FUbuntu-yellow?style=for-the-badge">
</p>

---
## About this script

This Bash script automates the **installation**, **configuration** of a **BIND9 DNS server** on Debian/Ubuntu systems. It sets up forward and reverse zones, adds DNS records, checks configurations, and restarts the service. Perfect for quick deployment in local or testing environments.

## 📦 Features

- Automatic installation of BIND9 and required dependencies
- Creation of forward and reverse zone files
- Addition of custom A and PTR records
- Configuration syntax check (`named-checkconf` / `named-checkzone`)
- BIND9 service restart and enablement
- Hosts file update (`/etc/hosts`) with main entry
  
## 📋 Requirements

- A fresh **Debian/Ubuntu** server
- Root privileges (`sudo`)
- Internet access

---

## 🚀 How to Use

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Shaikos/ScriptBIND9.git
   cd ScriptBIND9
   ```

2. **Make the scripts executable:**

   ```bash
   chmod +x install_bind9_en.sh 
   ```

3. **Run the script as root:**

   ```bash
   sudo ./install_bind9_en.sh
   ```
   *(or `install_bind9_fr.sh` for the French version)*

4. **Follow the prompts:**
   - Enter the **domain name** (e.g., `example.local`)
   - Enter the **main hostname** (e.g., `ns1`)
   - Enter the **IP address** of the DNS server
   - *(Optional)* Add additional **A** and **PTR** records

5. **Verify the installation:**
   - Use `dig` or `nslookup` to test DNS resolution
   - Check BIND9 status:

     ```bash
     sudo systemctl status bind9
     ```

6. **(Optional)** Configure your system to use the new DNS server:
   - Edit `/etc/resolv.conf` or set it via your network manager
7. **(Optional)**
   - You can easily add hosts by running:
     ```bash
     sudo ./update_dns_en.sh
     ```
     *(or `update_dns_fr.sh` for the French version)*
---

## 📝 Example

```
➡️  Enter the domain name (e.g., mydomain.local): mynetwork.local
➡️  Enter the main hostname (e.g., dns-server): dns01
➡️  Enter the associated IP address (e.g., 192.168.1.10): 192.168.1.10
📌 Adding extra records (A + PTR) in network 192.168.1.x
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

---

## 📜 License

This project is open-source under the **MIT license**.  
Feel free to modify, improve, and share it!

---
