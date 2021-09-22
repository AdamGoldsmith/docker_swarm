# Docker Swarm deployment using Ansible & Vagrant

Collection of playbooks and roles to prepare and deploy hosts to run in a Docker swarm development/test cluster. Backend storage uses GlusterFS which is ideal in production environments for persistent storage across nodes. A playbook is supplied to create a Vagrantfile from the Ansible inventory for creating an infrastructure using the VirtualBox hypervisor.

## TL;DR

From root directory of repo:

1. `./scripts/ansible_venv.sh && source ~/venvs/ansible_ds/bin/activate` (__Optional__ step that creates & sources an ansible-enabled python virtual environment [__Requires python3__])
1. `ansible-playbook playbooks/vagrant/prepare_vagrant.yml -e "vagrant_script_check=no"`
1. `cd vagrant && vagrant up && cd ..`
1. `./scripts/prepare_ansible_targets.sh`
1. `ansible-playbook playbooks/site.yml`
1. Point browser at http://10.11.12.11:8088 to access [visualizer](https://github.com/dockersamples/docker-swarm-visualizer)
1. Point browser at http://10.11.12.11:8081 to access [phpmyadmin](https://www.phpmyadmin.net)
1. Point browser at http://10.11.12.11:8080 to access [nginx](https://www.nginx.com)

## Overview of architecture

__Note:__ Following diagram shows a representation of the deployed infrastructure

![Architecture overview](images/architecture.png?raw=true "Title")

__Note:__ Following Google Slides deck overviews the deployment on the developer's machine

[Deployment presentataion](https://docs.google.com/presentation/d/e/2PACX-1vRZIxsDLc6ltGR6pgmuq7ldWOj8fI9vT54zi7uCcQfz35KPs5n-Atqp2xOTMZ2IS4TtcofueKL2416U/pub?start=false&loop=false&delayms=5000)

## Overview of tasks

When `site.yml` is run with default options, the following tasks will be applied in this order. Each main task can be run by supplying `--tags` - see [here](#running-the-deployment) for details.

1. Install python3 on docker target hosts (required for the pip3 docker SDK package)
1. Prepare firewall on docker target hosts as ports will be unavailable by default on CentOS 8. (Uses external Geerlingguy firewall role)
1. Configure GlusterFS on docker target hosts
    1. Install & configure GlusterFS (Uses external Geerlingguy glusterfs role)
    1. Prepare gluster directories
    1. Create gluster volumes
1. Preparing the hosts for Docker installation (Managed by the roles `ansible_role_user_prepare` & `ansible_role_dir_prepare`)
    1. Creating groups & users
    1. Configuring sudo access
    1. Installing LVM software
    1. Creating Volume Groups, Logical Volumes, Mountpoints & Filesystems
    1. Applying directory structure with correct ownership & permissions
1. Install Docker software packages (Managed by the role `ansible_role_docker_install`)
    1. Removing unused redundant Docker software packages
    1. Add Docker yum gpgkey & repository when not using private repositories
    1. Installing Docker software packages
    1. Start & enable Docker service
    1. Enable insecure Docker registries
1. Configure Docker Swarm (Managed by the playbook `docker_swarm`)
    1. Determine Docker swarm interface address
    1. Install pip Docker software to enable Ansible to manage Docker
    1. Configure Docker swarm manager
    1. Join Docker swarm workers to cluster
1. Deploy Docker swarm stacks on Docker Swarm manager node (Managed by the playbook `docker_stacks`)
    1. Identify docker stacks (if not specified)
    1. Synchronise docker-compose files to Docker Swarm manager node
    1. Create and run Docker Swarm stacks

##  Default `test` stack services

* [registry](https://hub.docker.com/_/registry)
* [visualizer](https://github.com/dockersamples/docker-swarm-visualizer)
* [web](https://hub.docker.com/_/nginx)
* [php](https://quay.io/repository/ignited/php-nginx-fpm)
* [phpmyadmin](https://www.phpmyadmin.net)
* [mysql](https://www.mysql.com)
* [mariadb](https://mariadb.org)

## Supported platforms

| Platform | Version | Default |
|----------|---------|---------|
| CentOS   | 7       |         |
| CentOS   | 8       | Yes     |

## Requirements

* Ansible 2.9+ (tested with 2.9.8 & 2.10.0)
* Python's netaddr module (pip - `netaddr`, yum - `python-netaddr`)
* Python's docker module (pip - `docker`)
* Vagrant (__*optional*__) (tested with 2.2.6)
* Python3 (__*optional*__) (for creating a virtual env using supplied utility script)

## Inventory

The inventory lives under the main `inv.d` directory. The inventory in this repo should work straight out of the box when deploying the infrastructure and the Docker Swarm stacks. This Ansible configuration has been setup to use `inv.d` by default in `ansible.cfg`.

The following example shows the supplied environment inventory in `inv.d/inventory`

```ini
localhost ansible_host=127.0.0.1 ansible_connection=local

[docker_manager]
ds-node-1 ansible_host=10.11.12.11

[docker_worker]
ds-node-2 ansible_host=10.11.12.12
ds-node-3 ansible_host=10.11.12.13
ds-node-4 ansible_host=10.11.12.14

[docker:children]
docker_manager
docker_worker

[gluster:children]
docker

[firewall:children]
docker
```

## Group & Host vars

In addition to the group & host variables required for each role (see their associated READMEs), the following group & host variables will need setting:

`inv.d/group_vars/firewall/firewall.yml`
```yaml
firewall_allowed_tcp_ports:                 # List of required tcp application ports to be opened
firewall_allowed_udp_ports:                 # List of required udp application ports to be opened
```
`inv.d/group_vars/gluster/gluster.yml`
```yaml
use_lvm:                                    # Enable LVM-based gluster config
vg_data:                                    # List of gluster LVM data (see file for details of structure)
gluster_data_structure:                     # List of gluster config & data directories (see file for details of structure)
gluster_volumes:                            # Gluster volumes to mount on the gluster nodes (see file for details of structure)
```
`inv.d/group_vars/docker/docker.yml`
```yaml
docker_user:                                # Name of docker system userid to create
user_data:                                  # Dictionary data for docker user (see file for details of structure)
group_data:                                 # Dictionary data for docker group (see file for details of structure)
sudo_groups:                                # List of users to add to sudo
docker_swarm_network:                       # Network mask used to detect the IP address of the Docker swarm host (see notes below on behaviour). Can be manually set to override the automatically-discovered value
docker_swarm_port:                          # Docker Swarm port (defaults to 2377)
local_stacks_dir:                           # Directory on local machine of all stack data (see 'stacks' dir for examples)
ds_data_path:                               # Docker Swarm base directory for storing stack compose files and data
```
`inv.d/group_vars/all/vars.yml`
```yaml
ansible_user: ansible                       # Ansible user on target host
verbosity_level: 0                          # Verbosity level when to display debug output (0 = always, 1 = -v, 2 = -vv, etc)
```

__Notes:__

__`docker_swarm_network`__

This is a network range used by Ansible to detect the correct interface/IP address for the Docker swarm manager/worker advertised address configuration. There are various behaviours related to how it is set, for example:

* `undefined` Uses the IPv4 address that relates to the inventory's ansible_host (default)
* `10.1.88.0/24` Sets the Docker swarm advertising address to the first adapter in that range, eg. `10.1.44.101`
* `0.0.0.0/0` Uses the first adapter it finds as ALL IPv4 addresses will be in this global range

## Optional use of Ansible in Python3 virtual environment

This repo supplies a utility script for creating an Ansible virtual environment with the necessary pip package dependencies installed. This is a convenient way to run Ansible in a dedicated environment without installing it directly onto the host operating system. Run the following from the repo root directory to create & activate the Ansible venv.

```
./scripts/ansible_venv.sh && source ~/venvs/ansible_ds/bin/activate
```

__Note:__ To deactivate the venv, run `deactivate` from any directory

## Optional use of Vagrant

This repo supplies an Ansible playbook that locally creates a Vagrantfile and target preparation script using the contents of the Ansible inventory. These can be used to provision and prepare a complete [VirtualBox](https://www.virtualbox.org) test infrastructure using [Vagrant](https://www.vagrantup.com) ready for the Docker swarm deployment. Although it is designed to work out of the box by design, please ensure that the following vagrant variables are configured correctly.

`inv.d/host_vars/localhost.yml`
```yaml
vagrant_box_version: "centos/8"                           # Flavour and version of Vagrant Box (supports centos/7 too)
vagrant_guest_additions: False                            # Boolean for installing guest additions software
vagrant_domain: ""                                        # Domain name for vagrant hosts
vagrant_script_check: True                                # Defaults the prepare_ansible_targets.sh script to run in check mode
vagrant_python_interpreter: auto                          # Ansible python interpreter
vagrant_connect_user: vagrant                             # VM connection user created by vagrant
vagrant_ansible_user_uid: 9999                            # UID for ansible user
vagrant_connect_user_privkey_file: ~/.ssh/id_rsa          # Path to private SSH key used to connect to VM
vagrant_ansible_user_pubkey_file: ~/.ssh/id_rsa.pub       # Path to publc SSH key pair file
```

1. Running the following Ansible playbook will
    1. Create the `vagrant` & `scripts` directories
    1. Create the `Vagrantfile`
    1. Create the `prepare_ansible_targets.sh` script
    1. Copy the SSH public key into the `vagrant` directory

```
ansible-playbook playbooks/vagrant/prepare_vagrant.yml
```

__Note:__ *To override the default enabled script check mode, run with: `-e "vagrant_script_check=no"`*

2. Running the following command will bring the entire infrastructure online

```
cd vagrant; vagrant up; cd ..
```

3. Running the `prepare_ansible_targets.sh` script will use the initial vagrant user to
    1. Create the ansible user on the target hosts
    1. Update the ansible user's `authorized_keys` file on the target hosts with the specified public SSH key
    1. Add the ansible user to sudo with passwordless access

```
./scripts/prepare_ansible_targets.sh
```

At this point, a complete test infrastructure will now be provisioned, ready to be configured!

## Stack deployment

The Docker stacks are deployed using `docker-compose` files located in the `stacks` directory. The base `docker-compose.yml` file is always used, and the optional overlay compose files are determined by the `docker_stack_env` ansible variable. For example, if `docker_stack_env` is set to `test` and there exists a compose file called `docker-compose-test.yml`, then this will be used as an override compose file.

By default all stacks are deployed (stacks are defined by directories under `stacks`), however you can specify the ansible variable `docker_stack_names` as a list of specific stacks to deploy.


## Running the deployment

1. To perform a full deployment of all components to the default environment (production)
    ```
    ansible-playbook playbooks/site.yml
    ```
    __Note:__ *For additional debug output, set the verbosity level with: `-e "verbosity_level=0"`*

1. To only prepare and install Docker
    ```
    ansible-playbook playbooks/site.yml --tags docker
    ```

1. Then to later deploy only the Docker swarm components (requires that the prepare and install parts have already run)
    ```
    ansible-playbook playbooks/site.yml --tags swarm
    ```

1. To deploy only the `db` & `web` stacks with the associated base & __test__ docker-compose files

    ```
    ansible-playbook playbooks/site.yml --tags docker_stacks -e '{"docker_stack_names": ["db","web"]}' -e 'docker_stack_env=test'
    ```

>__Note__: There is no option to destroy this configuration. You are advised to create a new environment and re-deploy this configuration

This can easily be achieved when using vagrant:

```
cd vagrant; vagrant destroy --force; vagrant up; cd ..
```

## Author Information

Adam Goldsmith

## References

| Link | Author |
|------|--------|
| [GlusterFS role](https://galaxy.ansible.com/geerlingguy/glusterfs) | Jeff Geerling |
| [Firewall role](https://galaxy.ansible.com/geerlingguy/firewall) | Jeff Geerling |
| [Docker + GlusterFS Article](https://www.frederikbanke.com/docker-setup-part-8-glusterfs-and-docker-on-multiple-servers/) | Frederik Banke |
