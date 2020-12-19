#!/bin/bash

# Drain random active node to test service cycling

# Set script_dir to directory of script
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $(dirname ${script_dir})

while true
do
  ansible docker_manager -b -a "docker node ls"
  ansible docker_manager -b -a "docker service ps test_nfs -f desired-state=Running"

  for nastiness in $(seq 1 ${1:-1})
  do
    active_nodes=($(ansible docker_manager -b -a "docker node ls --filter role=worker --format '{{ '{{' }}.Hostname{{ '}}' }} {{ '{{' }}.Availability{{ '}}' }}'" | awk '$2=="Active" {print $1}'))
    # Pick a random node from the list of active nodes
    # ${#active_nodes[@]} is the size of array
    if [[ ${#active_nodes[@]} -ne 0 ]]
    then
      random_index=$(($RANDOM % ${#active_nodes[@]}))
      active_node=${active_nodes[${random_index}]}

      echo "Draining ${active_node}"
      ansible docker_manager -b -a "docker node update --availability drain ${active_node}"
    fi
  done

  for drained_node in $(ansible docker_manager -b -a "docker node ls --format '{{ '{{' }}.Hostname{{ '}}' }} {{ '{{' }}.Availability{{ '}}' }}'" | awk '$2=="Drain" {print $1}')
  do
    echo "Activating ${drained_node}"
    ansible docker_manager -b -a "docker node update --availability active ${drained_node}"
  done

  sleep 15

  ansible docker_manager -b -a "docker service ps test_nfs -f desired-state=Running"
  for service_id in $(ansible docker_manager -b -a "docker service ps test_nfs -f desired-state=Running --format '{{ '{{' }}.ID{{ '}}' }}'" | grep -v CHANGED)
  do
    container_id=$(ansible docker_manager -b -a "docker inspect --format '{{ '{{' }}.Status.ContainerStatus.ContainerID'{{ '}}' }}  ${service_id}" | tail -1)
    echo "Service is running in container: ${container_id}"
  done

  sleep 20
done
