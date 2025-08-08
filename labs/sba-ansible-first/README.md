# Linux + Ansible SBA Automation

## Overview

This project was developed as part of the Skills-Based Assessment (SBA) for CST8246 – Linux Administration at Algonquin College.
The assessment's goal is to **deploy core services** on RHEL 8 manually or through scripting.

To challenge myself and deepen my understanding of automation,
I chose to go beyond the standard requirements and **use Ansible**. 
I automated the deployment and configuration of all required services.

---

## SBA Objectives

The required outcomes of the SBA include:

- SSH access configuration (key-based, restricted)
- Network access control using `iptables` and Netcat
- DNS setup with master-slave zone transfers

I built a reproducible environment where these services are provisioned and managed using **Ansible**.
The playbooks were deployed from a WSL Ubuntu client targeting RHEL 8 VMs.

---

## What This Project Does

- **SSH Hardening**:
  - Enables public key-only authentication
  - Grants access to `Thursday`, `foo`, and `root` accounts
  - Deploys client keys securely and restarts `sshd`

- **Firewall and Netcat Testing**:
  - Listens on port `59977`
  - **Allows** connections from `SERVER` (172.16.30.0/24) and `ALIAS` (172.16.32.0/24)
  - **Rejects** connections from the `CLIENT` network (172.16.31.0/16)

- **DNS Services**:
  - Configures `ns1 & ns2` (master) on 172.16.30.MN, 172.16.32.MN
  - Zone files and `named.conf` are deployed and verified
  - Zone transfer is tested and confirmed

- **Modular Playbooks**:
  - Each service is separated into its own role
  - Supports repeatable, idempotent provisioning

---

## Tools and Technologies

- Two RHEL 8 VMs
- Ansible (run from WSL Ubuntu on Windows)
- SSH (key-based auth only)
- iptables
- BIND (`named`)
- Netcat (nc)

## Future Improvements

This project could be improved further in the following ways:

- **Automated Validation with Ansible**  
  I currently use a Bash script that launches multiple `tmux` sessions from the client VM. These sessions SSH into the servers to test `nc` connectivity, DNS resolution with `dig`, and SSH restrictions. In the future, I plan to move this logic into Ansible playbooks using `local_action`, `delegate_to`, or command modules for full automation. I'm also learning more about Jinja2 templating to make my playbooks more dynamic and capable of doing exactly what I want.

- **Centralizing Variables**  
  Many configuration values like IPs, usernames, and domain names are currently hardcoded. I plan to move these into `group_vars/all.yml` to make the project more modular, maintainable, and easier to reuse in other setups.


Author
Hmoad Hajali
Level 3 CST – Networking Student
Algonquin College
