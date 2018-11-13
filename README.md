## Bootstrap Kubernetes with QEMU

<p align="center">
  <img src="https://raw.githubusercontent.com/zimmertr/Bootstrap-Kubernetes-with-QEMU/master/screenshot.png" width="800">
</p>

# Summary
Build a 4 node Kubernetes cluster on a Proxmox cluster using Ansible and QEMU.

**Approximate deployment time:** 25 minutes

# Requirements
1. Proxmox server
2. DNS Server
3. Ansible 2.7.0+. Known incompatibility with a previous build.
5. Fix `*.raw` disk issue
6. Implement identification of different types of storage mounts

# Instructions
**Required:**

1. Modify the `vars.yml` file with values specific to your environment.
2. Provision DNS A records for the IP Addresses & Hostnames you defined for your nodes in the `vars.yml` file.
3. Modify the `inventory.ini` file to reflect your chosen DNS records and the location of the SSH keys used to connect to the nodes.
4. Run the deployment: `ansible-playbook -e @vars.yml -i inventory.ini site.yml`
5. After deployment, a `~/.kube` directory will be created on your workstation. Within your `config` and an `authentication_token` file can be be found. This token is used to authenticate against the Kubernetes API and Dashboard using your account. To connect to the dashboard, install `kubectl` on your workstation and run `kubectl proxy` then navigate to the [Dashboard Endpoint](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/) in your browser.

**Optional:**

1. If you have an NFS server you can enable optional support for dynamic provisioning of Persistent Storage volumes for your pods by filling in the additional parameters in `vars.yml` and running this playbook: `ansible-playbook -e @vars.yml -i inventory.ini playbooks/deploy_nfs.yml`

# Tips
1. You can rollback the entire deployment with: `ansible-playbook -e @vars.yml -i inventory.ini delete_all_resources.yml`
2. If Calico isn't deploying correctly it's likely the CIDR you assigned to it in `vars.yml` conflicts with your network. 
3. See [this repository](https://github.com/zimmertr/Bootstrap-Kubernetes-with-LXC) to do this with LXC instead.  Benefits of using LXC include:
```
* No virtualization overhead means better performance
* Ability to directly mount volumes from your server into your containers.
```

# TODO
1. Add better support for multi-node Proxmox clusters.
2. Add support for VLAN Tags & IDs.
3. Perform security audit and enhance if necessary.
4. Add info to README about updating inventory file and how to handle SSH key generation and propegation.

# Problems
1. The `proxmox_kvm` module is out of date and does not support cloudinit related api calls. Meaning shell commands must be used instead to perform `qm create` tasks. 
2. The `k8s` module does not support applying Kubernetes Deployments from URL. Instead of using `get_url` to download them first, and then apply them with `k8s`, I just use `shell` to run a `kubectl apply -f`. [Feature Request here](https://github.com/ansible/ansible/issues/48402).
3. Miscellaneous `qcow2` image issues:
    * The Debian `qcow2` image encounters a Kernel Panic on the first boot for some reason. A hack has been put in place to get around this by stopping and     restarting them after 30 seconds. 
    * The CentOS `qcow2` image cannot be used due to [this bug] (https://bugs.centos.org/view.php?id=15426). 
    * The `CoreOS` qcow2 image does not have working networking after cloud-init does it's magic. 
    * A friend told me that the Ubuntu `qcow2` image also encounters a kernel panic on boot.
