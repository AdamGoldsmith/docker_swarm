#!/bin/bash

# One-time script for preparing ansible target hosts by:
#   1. Creating an automation user
#   2. Distributing SSH pub key to ansible hosts
#   3. Adding automation user to sudoers file

# Requirements:
#   Target hosts must have an existing admin user (connect_user) with sudo capabilities to create the new Ansible user
#   Private key file to authenticate connection as admin user (connect_user)
#   Public key file to add to newly-created Ansbile user's authorized_keys file

# How to run this script:
#   Edit the variables below to customise this script for your environment (a lot of the defaults assume it is the vagrant environment)
#   Change into the ansible directory (one directory above the 'scripts' directory)
#   Execute the script by running "./prepare_ansible_targets.sh"

# Update the following variables to customise the automation user configuration on the target hosts

check=0                                                      # Uses Ansible's --check flag when not set to 0
inventory="/home/golds_a/code/ds/inv.d/ds/inventory"         # The Ansible inventory to source
connect_user="vagrant"                                       # Existing admin user on target hosts used for creating the ansible user
ansible_user="ansible"                                       # Name of Ansible user to create on target hosts
ansible_user_uid="9999"                                      # UID of Ansible user on target hosts
connect_user_privkey_file="/home/golds_a/.ssh/id_rsa"        # Private key file of existing target host admin user
ansible_user_pubkey_file="/home/golds_a/.ssh/id_rsa.pub"     # Public key file to upload for newly-created ansible user (authorized_keys file entry)


function run_ansible {
  # -u doesn't override inventory-sourced connection user, using -e ansible_user=xxx instead
  if [[ "${check:-0}" -ne 0 ]]
  then
    echo "Running: ansible ${1} -i ${inventory} -e ansible_user=${2} --private-key ${3} -b -m ${4} -a ${5}" --check
    ansible -v "${1}" -i "${inventory}" -e "ansible_user=${2}" --private-key "${3}" -b -m "${4}" -a "${5}" --check
  else
    echo "Running: ansible ${1} -i ${inventory} -e ansible_user=${2} --private-key ${3} -b -m ${4} -a ${5}"
    ansible -v "${1}" -i "${inventory}" -e "ansible_user=${2}" --private-key "${3}" -b -m "${4}" -a "${5}"
  fi
}

for keyfile in "${connect_user_privkey_file}" "${ansible_user_pubkey_file}"
do
  [[ ! -e "${keyfile}" ]] && echo "No key file (${keyfile}) detected, exiting" && exit 1
done

run_ansible "docker,nfs" "${connect_user}" "${connect_user_privkey_file}" "user" "name=${ansible_user} state=present create_home=yes uid=${ansible_user_uid}"
run_ansible "docker,nfs" "${connect_user}" "${connect_user_privkey_file}" "authorized_key" "user=${ansible_user} state=present key={{ lookup('file', '${ansible_user_pubkey_file}') }}"
run_ansible "docker,nfs" "${connect_user}" "${connect_user_privkey_file}" "lineinfile" "path=/etc/sudoers line='${ansible_user} ALL=(ALL) NOPASSWD: ALL'"

# Confirm newly added user works
[[ "${check:-0}" -eq 0 ]] && run_ansible "docker,nfs" "${ansible_user}" "${connect_user_privkey_file}" "user" "user=${ansible_user}"
