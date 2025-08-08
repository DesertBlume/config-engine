#!/bin/bash

set -e  # Exit immediately on error

path="/home/desertblume/projects/automation/ansible/mail-ansible-setup/"

ansible-playbook -i "${path}inventory/lab-8-inventory.ini" "${path}playbooks/lab8-playbook.yml"

