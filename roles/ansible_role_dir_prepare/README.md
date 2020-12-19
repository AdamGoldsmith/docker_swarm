# ansible_role_dir_prepare

Creates directory structure (uses LVM by default) by:

* Installing LVM software
* Creating Volume Groups, Logical Volumes, Mountpoints & Filesystems
* Applying directory structure with correct ownership & permissions

Currently tested on these Operating Systems:

* CentOS 7

## Requirements

* Ansible 2.9+ (tested with 2.9.8 & 2.10.0)
* Users & groups exist on the host

## Role Variables

`defaults/main.yml`
```yaml
use_lvm: yes                                  # Create Volume Groups, Logical Volumes and Filesystems

lvm_packages:                                 # LVM software packages to be installed
  - 'lvm*'

vg_data:                                      # Dictionary of volume group data
  - name: datavg                              # Volume group name
    disks:                                    # List of disks to create the volume group on
      - /dev/sdb
    lvs:                                      # Dictionary of logical volume data
      - name: data                            # Logical volume name
        size: "9728"                          # Logical volume size in MB
        mount: /data                          # Logical volume's mountpoint
        type: xfs                             # Logical volume type
      # Continue in this fashion

data_structure:                               # Dictionary of directories and their attributes
  - name: /data                               # Directory name
    owner: root                               # Directory owner
    group: root                               # Directory group
    mode: "0740"                              # Directory permissions
  # Continue in this fashion
  # - name: /data/db
  #   owner: root
  #   group: root
  #   mode: "0740"
```

## Dependencies

Requires elevated root privileges

## Example Playbook

```yaml
- name: Prepare docker directory structure
  hosts: docker
  gather_facts: no
  become: yes
  tags:
    - docker_prepare
    - docker

  tasks:

    - name: Run directory preparation role
      include_role:
        name: ansible_role_dir_prepare
```

## Author Information

Adam Goldsmith
