## Bootstrap Kubernetes with Ansible

# Summary
Build a 4 node Kubernetes cluster on a Proxmox cluster using Ansible and either Linux Containers (LXC) or Virtual Machines.

# Requirements
1) A Proxmox server.
2) Ability to provision DNS records
3) Ansible 2.7.0+. Known incompatibility with a previous build. 

# Instructions

1) Modify the vars files with values specific to your environment and desires. Only the `LXC Options` or `qcow2 Options` section needs to be modified, as per your deployment model. 
2) Provision DNS A records for the IP Addresses & Hostnames you defined for your nodes in the `vars.yml` file.
3) Modify the inventory file to reflect your chosen DNS records.
4) Comment|Uncomment the required playbooks in the `site.yml` file.
5) Deploy Kubernetes: `ansible-playbook -e @Vars/vars.yml -i Inventories/inventory.ini site.yml`


# Tips

1) If your LXC instances fail to install `openssh-server` and throw a long `yum` related error, it's likely that they do not have a properly configured network. You can troubleshoot this by using the `lxc-attach` command to connect to them from Promxox without SSH. 
2) You can rollback the deployment and all modifications made to your Proxmox server by executing the `delete_all_resources.yml` playbook. For example: `ansible-playbook -e @Vars/vars.yml -i Inventories/inventory.ini Playbooks/delete_all_resources.yml`
3) The `delete_all_resources.yml` playbook is expected to throw errors, so do not panic. It is a catch all solution to delete all containers or virtual machines in one go. So, since you will only ever be using one deployment model, it will consistently fail to delete the resources from the other deployment model. This will not cause the playbook to fail. However, it is possible that the playbook will fail to unload the overlay module if it is currently in use by another kernel module. This is unavoidable. 


# TODO

1) Expand the `deploy_lxc_containers.yml` and `deploy_qcow2_vms.yml` playbooks to have better support for multi-node Proxmox clusters.
2) Expand the `deploy_lxc_containers.yml` and `deploy_qcow2_vms.yml` playbooks to have better support for vLAN Tags & IDs.
2) Fix issues affecting qcow2 deployment including insanely long SSH connectivity duration & privilege escalation prompt.
3) Fix linked clone volume assignment issue & remove commented out lines.
4) Rewrite `deploy_lxc_containers` to deploy one instance and clone rather than four separate instances to reduce duration.
5) Perform security enhancements. Like disabling `root` user from SSHing in on LXC container instances.
6) Consider removing the DNS record provisoning requirement by making references to IP Addresses instead. 
7) Copy `.kube` information to each of the Agents as well as the Proxmox server. Somehow copy to local machine for user?

# Problems

1) The command `qm` in Proxmox does not support provisoning a network interface when performing a clone from a template. This means that qemu will automatically configure a NAT and inject network configuration on the 10.0.2.0/24 address space. Causing DNS problems on the VM that will prevent Ansible from successfully connecting before the timeout while `UseDNS no` is not set in your `sshd_config` on the VMs. Which, unfortunately, would require Ansible to undo. This catch 22 situation means that templates are NOT able to be used for the `qcow2` solution effectively tripling the deployment duration. More information can be found here: https://serverfault.com/questions/937465/ansible-fails-at-gathering-hosts-presumably-because-ssh-is-slow-to-connect-se
2) The `proxmox_kvm` module is out of date and does not support cloudinit related api calls. Meaning shell commands must be used instead to perform `qm create` tasks. 
3) There is a bug in either the `4.15.18` Linux kernel or in the `br_netfilter` module. Preventing the LXC strategy from being a viable solution due to pod networking never being able to work. More information can be found here: https://github.com/lxc/lxd/issues/5193#issuecomment-431872713A A cluster can still be provisioned without pod networking, for what it is worth. 
