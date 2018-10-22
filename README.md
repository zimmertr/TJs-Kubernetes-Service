## Bootstrap Kubernetes with Ansible

# Summary
This project leverages Ansible and Proxmox to build a four node cluster with LXC instances or VMs.

# Requirements
1) A configured Proxmox server
2) Ability to provision DNS records
3) Ansible 2.7.0+. Known incompatibility with a previous build. 
4) https://pypi.org/project/proxmoxer/
```
apt-get install python-pip
pip install proxmoxer
```
5) Clustered Proxmox. (No worries, this can be done with a single host)

# Instructions

1) Modify the vars files with values specific to your environment.
2) Provision internal DNS A records for the IP Addresses & hostnames you defined for your nodes.
3) Update the inventory file to reflect your DNS records and LXC/qcow2 deployment strategy.
3) Deploy environment: `ansible-playbook -e @Vars/vars.yml -i Inventories/inventory.ini site.yml`
4) ???
5) Profit

# Tips

1) If the playbook fails when trying to install openssh-server and throws a weird `yum` error, it's likely your resources don't have network connectivity.
2) Delete environment: `ansible-playbook -e @Vars/vars.yml -i Inventories/inventory.ini Playbooks/delete_all_resources.yml`
3) The `delete_all_resources.yml` is a catch all playbook to delete all possible resources deployed. Therefore, many errors are expected to occur.
3) It's possible that the `delete_all_resources.yml` playbook will fail to unload the overlay module if it is currently in use. 

# TODO

1) Rewrite `deploy_qcow2_vms.yml` to have better proxmox cluster support.
2) Support vlan tags.
3) Determine why it takes so darn long to connect to the qcow2 VMs via SSH.
4) Fix privilege escalation prompt issue with qcow2 VMs. 

# Problems

1) There is a bug in either the `4.15.18` Linux kernel or in the `br_netfilter` module. Preventing the LXC strategy from being a viable solution due to pod networking never being able to work. :( 