# ansible_role_docker_install

Installs and starts docker service by:

* Removing out-dated redundant docker software packages
* Add docker yum gpgkey & repository
* Installing docker software packages
* Start & enable docker service
* Enable insecure regestries

Currently tested on these Operating Systems:

* CentOS 7

## Requirements

* Ansible 2.9+ (tested with 2.9.8 & 2.10.0)

## Role Variables

`defaults/main.yml`
```yaml
docker_edition: ce                            # Docker edition
docker_version: ""                            # Docker version, latest when undefined or blank (will not downgrade)

docker_pip_packages:                          # For Docker API communications
  # Needed for Ansible docker_swarm module
  # https://docs.ansible.com/ansible/latest/collections/community/general/docker_swarm_module.html#requirements
  - docker
  # Needed for Ansible docker_stack module
  # https://docs.ansible.com/ansible/latest/collections/community/general/docker_stack_module.html#requirements
  - jsondiff
  - pyyaml

docker_repo_data:                             # Dictionary of docker repo information
  url: https://download.docker.com/linux/centos/docker-{{ docker_edition }}.repo
  gpg_key: https://download.docker.com/linux/centos/gpg

old_docker_packages:                          # List of unused docker software packages for removal
  - docker
  - docker-client
  - docker-client-latest
  - docker-common
  - docker-latest
  - docker-latest-logrotate
  - docker-logrotate
  - docker-engine

docker_packages:                              # List of docker packages to install
  - "docker-{{ docker_edition }}{{
      ((docker_version is defined) and (docker_version | length > 0)) |
      ternary('-' + docker_version | default(''), '') }}"
  - "docker-{{ docker_edition }}-cli{{
      ((docker_version is defined) and (docker_version | length > 0)) |
      ternary('-' + docker_version | default(''), '') }}"
  - containerd.io

docker_insecure_regs: []                      # List of known private docker registries
```

## Dependencies

Requires elevated root privileges

## Example Playbook

```yaml
- name: Install Docker components
  hosts: docker
  gather_facts: no
  become: yes
  tags:
    - docker_install
    - docker

  tasks:

    - name: Run docker engine installation role
      include_role:
        name: ansible_role_docker_install
```

## Author Information

Adam Goldsmith
