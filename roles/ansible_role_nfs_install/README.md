# ansible_role_nfs_install

Installs, starts & configures NFS service by:

* Installing NFS software packages
* Start & enable NFS service
* Create filesystem entries and export them

Currently tested on these Operating Systems:

* CentOS 7

## Requirements

* Ansible 2.9+ (tested with 2.9.8 & 2.10.0)

## Role Variables

`defaults/main.yml`
```yaml

nfs_packages:                                 # NFS software packages
  - 'nfs-utils'
# /etc/exports entries are very specific, eg these have different meanings:
# /home bob.example.com(rw)
# /home bob.example.com (rw)
# Be specific how you create these entries (an example is shown below)

nfs_data: []                                  # List of filesytems to export (replaces existing same-named filesystems)
  # - /nfs 10.1.88.0/24(rw,sync,no_subtree_check)
```

## Dependencies

Requires elevated root privileges

## Example Playbook

```yaml
- name: Install NFS components
  hosts: nfs
  gather_facts: no
  become: yes
  tags:
    - nfs_install
    - nfs

  tasks:

    - name: Run nfs installation role
      include_role:
        name: ansible_role_nfs_install
```

## Author Information

Adam Goldsmith
