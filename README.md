## Bootstrap Kubernetes with Ansible

#Summary
This project leverages Ansible and Proxmox to build a four node cluster with Linux Containers (LXC)

#Instructions

1) Modify the vars files with values specific to your environment and desires.
2) Provision internal DNS A records for the IP Addresses & hostnames you defined for your nodes.
3) `ansible-playbook -e @Vars/vars.yml -i Inventories/Kubernetes_LXC.ini site.yml`
4) ???
5) Profit
