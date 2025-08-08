# Final SBA Automation - Ansible Deployment

This project is a fully automated infrastructure deployment for a simulated final SBA lab. It provisions and configures multiple services on a Red Hat-based server VM using **Ansible**, **Podman**, and **iptables**, with verification scripts included to validate functionality.

---

## 📦 Services Configured

### ✅ Master/Slave DNS (BIND9)

* Master: `dns1.blue.lab` → `172.16.30.48`
* Slave:  `dns2.blue.lab` → `172.16.32.48`
* Forward and reverse zones for `blue.lab`
* Slave pulls zones via `AXFR` zone transfer

### ✅ Advanced Web Hosting (Apache)

* Apache container hosts 3 virtual websites:

  * `www1.blue.lab` (HTTP)
  * `www2.blue.lab` (HTTP)
  * `secure.blue.lab` (HTTPS on alias IP)
* Uses name-based virtual hosts
* Each site displays `MAGIC#48` and its domain name

### ✅ Advanced Mail (Postfix/Dovecot)

* **Incoming mail** for `labfinal@blue.lab` redirects to local user `foo`
* **Outgoing mail** is masqueraded to `blue.lab`
* Verified using `mailx`/`mutt` or Roundcube (optional future setup)

### ✅ LDAP with Host Entry (optional for now)

* Will be configured via 389 Directory Server
* Example host entry: `www.ict.lab` with `ipHostNumber` and `cn`

### ✅ Samba Private Share

* Share: `/srv/samba/private`
* `user1`: read/write (must create `ReadMe.smb`)
* `user2`: read-only (verified via ACL and script)

### ✅ NFS Restricted Share

* Exported: `/srv/nfs`
* `172.16.31.0/24`: read/write
* `172.16.30.0/24`: read-only
* Enforced via `/etc/exports` and tested with root-squash behavior

---

## 🔥 Firewall (iptables)

* **Default policy:** Drop all inbound
* **Allowed by design:**

  * SSH: TCP 22
  * DNS: TCP/UDP 53
  * HTTP: TCP 80
  * HTTPS: TCP 443
  * Mail (SMTP): TCP 25
  * LDAP: TCP 389
  * Samba: TCP 139, 445 + UDP 137, 138
  * NFS: TCP/UDP 2049 + rpcbind/mountd (111, 20048)
* **Access control:**

  * Allow: `172.16.31.0/24` (client)
  * Block: `172.16.30.0/24`, `172.16.32.0/24` (except for NFS read-only)

---

## 🔁 Containerized Services

* All major services (DNS, Apache, etc.) are deployed inside **Podman containers**
* Images are fetched via `get_url` from the host machine (Ubuntu)
* BIND and Apache use volume mounts for persistent config

---

## 👤 Users & Permissions

| User      | Password  | Permissions     |
| --------- | --------- | --------------- |
| `root`    | `abc`     | Full admin      |
| `foo`     | `bar`     | Mail recipient  |
| `ansible` | `ansible` | Deployment user |
| `final`   | `sba`     | General use     |
| `user1`   | `user1`   | Samba RW        |
| `user2`   | `user2`   | Samba RO        |

---

## 🧪 Verification Scripts

### ✔ verification\_client

* Runs on the client VM
* Verifies:

  * Zone transfers
  * Name resolution
  * Web access (HTTP/HTTPS)
  * Samba/NFS mount and permission test
  * Verifies slave zone sync and re-transfer

### ✔ verification\_server

* Runs on the server as user `ansible`
* Uses `sudo` internally for privileged operations
* Verifies:

  * Samba/NFS access
  * iptables rule dump
  * NFS read/write test as server

All logs are written to:

* `/root/verification.log` (client)
* `/home/ansible/verification.log` (server)

---

## 🧰 Role Overview

| Role                         | Description                         |
| ---------------------------- | ----------------------------------- |
| `common`                     | User creation, password setup       |
| `bind-master`                | BIND9 master zone configuration     |
| `bind_slave`                 | BIND9 slave setup                   |
| `apache-blue`                | Apache + SSL virtual host container |
| `samba`                      | Samba public/private share          |
| `nfs`                        | NFS export, ACLs, and permissions   |
| `iptables`                   | Firewall configuration with Ansible |
| `verification_client/server` | Scripts to validate functionality   |

---

## ⚙️ To Run

### Full Playbook:

```bash
ansible-playbook -i inventory/sba.ini sba-playbook.yml
```

### Specific Role (e.g. DNS only):

```bash
ansible-playbook -i inventory/sba.ini sba-playbook.yml --tags bind-master
```

---

## 📁 Directory Structure

```
roles/
├── apache-blue/
├── bind-master/
├── bind_slave/
├── common/
├── iptables/
├── nfs/
├── samba/
├── verification_client/
├── verification_server/
```

---

## 🙌 Author

**Hmoad Hajali**
Final SBA Project — CST8246
Algonquin College — August 2025


