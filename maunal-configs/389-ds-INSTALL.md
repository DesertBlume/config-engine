### Installing `389-ds-base` on RHEL 8.10 (SCA-Enabled Environment)

This guide documents the process for installing the 389 Directory Server (`389-ds-base`) on a RHEL 8.10 system using a Red Hat subscription under Simple Content Access (SCA), as commonly provided by academic institutions.

---

#### Prerequisites

* RHEL 8.10 system with a Red Hat subscription registered
* Simple Content Access enabled (`subscription-manager status` shows `Overall Status: Disabled`, but indicates content is available)

---

#### Step-by-Step Installation

##### 1. Confirm SCA Mode and Check Available Repositories

Verify system status:

```bash
sudo subscription-manager status
```

Then check for available AppStream repositories:

```bash
sudo subscription-manager repos --list | grep -i appstream -A 5
```

This outputs a list of repository IDs. Identify the correct AppStream repo for your system. In this case, the valid repo was:

```
Repo ID:   rhel-8-for-x86_64-appstream-rpms
Enabled:   1
```

If it's not enabled, enable it manually:

```bash
sudo subscription-manager repos --enable=rhel-8-for-x86_64-appstream-rpms
```

---

##### 2. Reset Any Active Module Streams for 389 Directory Server

Red Hat’s modular system may filter out packages if module streams are not configured properly. Run the following to reset the `389-ds` stream:

```bash
sudo dnf module reset 389-ds -y
```

---

##### 3. Enable the Correct Module Stream

Enable the appropriate module stream for the `389-ds` package:

```bash
sudo dnf module enable 389-ds -y
```

This enables the default stream (`1.4`) that contains `389-ds-base`.

---

##### 4. Clean Metadata and Make Cache

```bash
sudo dnf clean all
sudo dnf makecache
```

---

##### 5. Install the 389 Directory Server

```bash
sudo dnf install -y 389-ds-base
```

This will install the server along with its dependencies, including:

* `lib389` (Python interface for managing 389 DS)
* `dscreate`, `dsctl`, and related command-line utilities

---

#### Outcome

The 389 Directory Server was successfully installed on a RHEL 8.10 virtual machine using a subscription registered under Simple Content Access. The procedure has been tested and confirmed to work in this environment.

