# ansible_role_user_prepare

Creates & prepares users & groups by:

* Creating system groups & users
* Configuring sudo access

Currently tested on these Operating Systems:

* CentOS 7

## Requirements

* Ansible 2.9+ (tested with 2.9.8 & 2.10.0)

## Role Variables

`defaults/main.yml`
```yaml
group_data:                                   # Dictionary of groups to be added (repeat as necessary)
  - name: testgrp1                            # Name of group
    gid: 10100                                # GID of group

user_data:                                    # Dictionary of users to be added (repeat as necessary)
  - name: testuser1                           # Name of user
    group: testgrp1                           # Name of user's primary group
    # groups:                                 # List of user's additional groups
    #   - docker_admins
    #   - docker_infra
    #   - etc
    comment: Test user                        # User's comment field
    expires: -1                               # Expiration date in Epoch format (-1 never expires)
    home: /home/testuser1                     # User's home directory
    shell: /bin/false                         # User's shell (/bin/false means no login possible)
    uid: 10100                                # UID of user

sudo_groups: []                               # List of groups to add to sudo configuration
```

## Dependencies

Requires elevated root privileges

## Example Playbook

```yaml
- name: Prepare Docker environments
  hosts: docker
  gather_facts: no
  become: yes
  tags:
    - docker_prepare
    - docker

  tasks:

    - name: Run user preparation role
      include_role:
        name: ansible_role_user_prepare
```

## Author Information

Adam Goldsmith
