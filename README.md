## Bootstrap Kubernetes with Ansible

# Summary
This project leverages Ansible and Proxmox to build a four node cluster with Linux Containers (LXC)

# Requirements
1) A configured Proxmox server
2) Ability to provision DNS records
3) Ansible 2.7.0+. Known incompatibility with a previous build. 

# Instructions

1) Modify the vars files with values specific to your environment.
2) Provision internal DNS A records for the IP Addresses & hostnames you defined for your nodes.
3) Update the inventory file to reflect your DNS records.
3) `ansible-playbook -e @Vars/vars.yml -i Inventories/Kubernetes_LXC.ini site.yml`
4) ???
5) Profit