## ✅ Lab 8 - LDAP Setup and Hostname Resolution via NSS (Manual Deployment)

---

### 📦 Server: 389 Directory Server Setup (RHEL 8.10)

#### Step 1: Launch Interactive Setup

```bash
dscreate interactive
```

#### Step 2: Interactive Configuration

| Prompt                             | Value                                  |
| ---------------------------------- | -------------------------------------- |
| SELinux support disabled?          | yes (SELinux was already disabled)     |
| Hostname                           | (default) `haja0013-SRV.example48.lab` |
| Instance name                      | `ldap`                                 |
| Port number                        | `389`                                  |
| Create self-signed certificate DB? | `no`                                   |
| Directory Manager DN               | (default) `cn=Directory Manager`       |
| Directory Manager Password         | `cst8246cst8246`                       |
| Database suffix                    | `dc=example48,dc=lab`                  |
| Create sample entries?             | `no`                                   |
| Create just the top suffix entry?  | `no`                                   |
| Start instance after install?      | `yes`                                  |
| Confirm installation               | `yes`                                  |

#### Result

* Instance created: `ldap`
* Config: `/etc/dirsrv/slapd-ldap/`
* Data: `/var/lib/dirsrv/slapd-ldap/`

#### Enable and Start the Service

```bash
systemctl enable dirsrv@ldap
systemctl start dirsrv@ldap
```

#### Confirm Listening

```bash
ss -tulpn | grep :389
```

---

### 🧱 Directory Information Tree (DIT) Setup

#### 1. Create Base Entry

File: `/root/base.ldif`

```ldif
dn: dc=example48,dc=lab
objectClass: top
objectClass: domain
dc: example48
```

```bash
ldapadd -x -D "cn=Directory Manager" -W -H ldap://localhost -f /root/base.ldif
```

#### 2. Add Organizational Units

File: `/root/ou.ldif`

```ldif
dn: ou=accounts,dc=example48,dc=lab
objectClass: top
objectClass: organizationalUnit
ou: accounts

dn: ou=groups,dc=example48,dc=lab
objectClass: top
objectClass: organizationalUnit
ou: groups

dn: ou=hosts,dc=example48,dc=lab
objectClass: top
objectClass: organizationalUnit
ou: hosts
```

```bash
ldapadd -x -D "cn=Directory Manager" -W -H ldap://localhost -f /root/ou.ldif
```

#### 3. Add Users

File: `/root/users.ldif`

```ldif
dn: uid=linuser1,ou=accounts,dc=example48,dc=lab
objectClass: inetOrgPerson
objectClass: posixAccount
cn: linuser1
sn: User
uid: linuser1
uidNumber: 1001
gidNumber: 1000
homeDirectory: /home/linuser1
loginShell: /bin/bash
mail: linuser1@example48.lab
mail: linux.user1@example48.lab

dn: uid=linuser2,ou=accounts,dc=example48,dc=lab
objectClass: inetOrgPerson
objectClass: posixAccount
cn: linuser2
sn: User
uid: linuser2
uidNumber: 1002
gidNumber: 1000
homeDirectory: /home/linuser2
loginShell: /bin/bash
mail: linuser2@example48.lab

dn: uid=haja0013,ou=accounts,dc=example48,dc=lab
objectClass: inetOrgPerson
objectClass: posixAccount
cn: haja0013
sn: User
uid: haja0013
uidNumber: 1003
gidNumber: 1000
homeDirectory: /home/haja0013
loginShell: /bin/bash
mail: haja0013@example48.lab
```

```bash
ldapadd -x -D "cn=Directory Manager" -W -H ldap://localhost -f /root/users.ldif
```

#### 4. Add Group

File: `/root/group.ldif`

```ldif
dn: cn=users,ou=groups,dc=example48,dc=lab
objectClass: posixGroup
cn: users
gidNumber: 1000
memberUid: linuser1
memberUid: linuser2
memberUid: haja0013
```

```bash
ldapadd -x -D "cn=Directory Manager" -W -H ldap://localhost -f /root/group.ldif
```

#### 5. Add Host Entries

File: `/root/hosts.ldif`

```ldif
dn: cn=happy.example48.lab,ou=hosts,dc=example48,dc=lab
objectClass: device
objectClass: ipHost
cn: happy.example48.lab
ipHostNumber: 172.16.32.48
description: Happy server

dn: cn=peachy.example48.lab,ou=hosts,dc=example48,dc=lab
objectClass: device
objectClass: ipHost
cn: peachy.example48.lab
ipHostNumber: 172.16.33.48
description: Peachy server
```

```bash
ldapadd -x -D "cn=Directory Manager" -W -H ldap://localhost -f /root/hosts.ldif
```

---

### 👤 Create LDAP Bind User (Optional if not using anonymous bind)

File: `/root/ldap-bind-user.ldif`

```ldif
dn: uid=ldapbind,ou=accounts,dc=example48,dc=lab
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
objectClass: top
cn: ldapbind
sn: bind
uid: ldapbind
userPassword: cst8246cst8246
```

```bash
ldapadd -x -D "cn=Directory Manager" -W -H ldap://localhost -f /root/ldap-bind-user.ldif
```

---

### 🌐 Enable Anonymous Read Access to DIT

File: `/root/anonymous-aci-dit.ldif`

```ldif
dn: dc=example48,dc=lab
changetype: modify
add: aci
aci: (targetattr = "*")
     (version 3.0; acl "Allow anonymous read of DIT";
     allow (read, search, compare)
     userdn = "ldap:///anyone";)
```

```bash
ldapmodify -x -D "cn=Directory Manager" -W -H ldap://localhost -f /root/anonymous-aci-dit.ldif
```

---

### 🖥️ Client Setup for NSS Hostname Resolution (RHEL 8.10)

#### 1. Install Packages

```bash
dnf install -y openldap openldap-clients nss-pam-ldapd
```

#### 2. Configure `/etc/openldap/ldap.conf`

```conf
BASE    dc=example48,dc=lab
URI     ldap://172.16.30.48
```

#### 3. Configure `/etc/nslcd.conf`

```conf
uri ldap://172.16.30.48
base dc=example48,dc=lab
base hosts ou=hosts,dc=example48,dc=lab
```

> If not using anonymous access, also add:

```conf
binddn uid=ldapbind,ou=accounts,dc=example48,dc=lab
bindpw cst8246cst8246
```

#### 4. Start and Enable nslcd

```bash
systemctl enable --now nslcd
```

#### 5. Update `/etc/nsswitch.conf`

```conf
hosts: files dns ldap
```

If managed by `authselect`, ensure you are using the `minimal` profile:

```bash
authselect select minimal --force
```

Then manually edit `/etc/nsswitch.conf` to ensure `ldap` is included.

---

### ✅ Testing

```bash
getent hosts happy.example48.lab
getent hosts peachy.example48.lab
```

Expected:

```text
172.16.32.48  happy.example48.lab
172.16.33.48  peachy.example48.lab
```

Congratulations — LDAP and NSS integration complete and verified!

