# TKS (TJ's Kubernetes Service)

<p align="center">
  <img src="https://raw.githubusercontent.com/zimmertr/Bootstrap-Kubernetes-with-QEMU/master/screenshot.png" width="800">
</p>

## Summary
Declaratively build a 4 node Kubernetes cluster on Proxmox using Ansible and QEMU. Optionally enable NFS & bare metal load balancing.

**Approximate deployment time:** 25 minutes


## Requirements
1. Proxmox server
2. DNS Server
3. Ansible 2.7.0+. Known incompatibility with a previous build.


## Instructions
**Required:**

1. Modify the `vars.yml` file with values specific to your environment.
2. Provision DNS A records for the IP Addresses & Hostnames you defined for your nodes in the `vars.yml` file.
3. Modify the `inventory.ini` file to reflect your chosen DNS records and the location of the SSH keys used to connect to the nodes.
4. Run the deployment: `ansible-playbook -i inventory.ini site.yml`
5. After deployment, a `~/.kube` directory will be created on your workstation. Within your `config` and an `authentication_token` file can be be found. This token is used to authenticate against the Kubernetes API and Dashboard using your account. To connect to the dashboard, install `kubectl` on your workstation and run `kubectl proxy` then navigate to the [Dashboard Endpoint](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/) in your browser.

**Optional:**

*To enable an optional feature, fill in the additional parameters in `vars.yml` and execute a playbook listed below.*

| Feature | Command | Requirements |
| ------- | ------- | ------------ |
| [NFS backed persistent storage](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client) | `ansible-playbook -i inventory.ini playbooks/optional/deploy_nfs.yml` | |
| [MetalLB Load Balancer](https://metallb.universe.tf) | `ansible-playbook -i inventory.ini playbooks/optional/deploy_metallb.yml` | | 
| [NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx) | `ansible-playbook -i inventory.ini playbooks/optional/deploy_ingress-nginx.yml` | [MetalLB](https://metallb.universe.tf/) or other Load Balancer integration |
| [DataDog agents](https://docs.datadoghq.com/integrations/kubernetes/) | `ansible-playbook -i inventory.ini playbooks/optional/deploy_datadog.yml` | |


## Tips
1. You can rollback the entire deployment with: `ansible-playbook -i inventory.ini playbooks/optional/delete_all_resources.yml`
2. If Calico isn't deploying correctly it's likely the CIDR you assigned to it in `vars.yml` conflicts with your network. 
3. See [this repository](https://github.com/zimmertr/Bootstrap-Kubernetes-with-LXC) to do this with LXC instead.  Benefits of using LXC include:
```
* No virtualization overhead means better performance
* Ability to directly mount volumes from your server into your containers.
```


## TODO
1. Add better support for multi-node Proxmox clusters.
2. Add support for VLAN Tags & IDs.
3. Perform security audit and enhance if necessary.
4. Add info to README about updating inventory file and how to handle SSH key generation and propegation.
5. Add playbook to integrate k8s with a log server.
6. Fix `*.raw` disk issue.
7. Implement identification of different types of storage mounts.
8. Automatically include `inventory.ini` somehow so one can simply run `ansible-playbook site.yml` to deploy.
9. Create playbook to upgrade kubernetes version for kubeadm cluster.
10. Create playbook to install OS updates on nodes.
11. Move dashboard deployment to optional features.


## Problems
1. The `proxmox_kvm` module is out of date and does not support cloudinit related api calls. Meaning shell commands must be used instead to perform `qm create` tasks. 
2. The `k8s` module does not support applying Kubernetes Deployments from URL. Instead of using `get_url` to download them first, and then apply them with `k8s`, I just use `shell` to run a `kubectl apply -f`. [Feature Request here](https://github.com/ansible/ansible/issues/48402).
3. Miscellaneous `qcow2` image issues:

| OS | Issue |
| -- | ----- |
| Debian | Kernel Panic on the first boot. Bypassed by stopping and starting a VM after 30 seconds. |
| CentOS | A nameserver is baked into `/etc/resolv.conf` by default. [Bug Report here](https://bugs.centos.org/view.php?id=15426) |
| CoreOS | Proxmix issued cloud-init does not seem to configure networking properly. |
| Ubuntu | Kernel Panic on the first boot. Bypass hack is untested as I prefer Debian. |
