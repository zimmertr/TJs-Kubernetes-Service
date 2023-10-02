# TJ's Kubernetes Service

## Summary

TJ's Kubernetes Service, or *TKS*, is an IaC project that is used to deliver Kubernetes to Proxmox. Across the years, it has evolved many times and has used a multitude of different technologies. Nowadays, it is a relatively simple collection of Terraform manifests thanks to the work of [BPG](https://github.com/bpg/terraform-provider-proxmox) and [Sidero Labs](https://github.com/siderolabs/terraform-provider-talos). 

## Instructions

1. Configure SSH access with a private key to your Proxmox server. This is needed to provision the installation image and also for [certain API actions](https://registry.terraform.io/providers/bpg/proxmox/latest/docs#api-token-authentication) executed by the Terraform provider.

2. Create an API token on Proxmox. I personally use [this Ansible role](https://github.com/zimmertr/Bootstrap-Proxmox/blob/master/roles/configure_terraform_user/tasks/main.yml).

3. Add your SSH key to `ssh-agent`:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add --apple-use-keychain ~/.ssh/sol.Milkyway
   ```

4. Review `variables.tf` and set any overrides according to your environment in `config.env`. Load the variables into your shell. `CLUSTER_ID` is not required, but can be used to enable deploying multiple Kubernetes clusters with the same basic configuration. 
   ```bash
   source config.env
   ```

5. Create DNS records and DHCP reservations for your nodes according to your configured Hostname, MAC address, and IP Address prefixes. Due to the way the values are generated in Terraform, there is a limit of 9 control planes and 9 worker nodes. Here is how mine is configured for two clusters:

   | Hostname        | MAC Address       | IP Address     |
   | --------------- | ----------------- | -------------- |
   | k8s-vip         | N/A               | 192.168.40.20  |
   | k8s-cp-1        | 00:00:00:00:00:21 | 192.168.40.21  |
   | k8s-cp-2        | 00:00:00:00:00:22 | 192.168.40.22  |
   | k8s-cp-3        | 00:00:00:00:00:23 | 192.168.40.23  |
   | k8s-node-1      | 00:00:00:00:00:31 | 192.168.40.31  |
   | k8s-node-2      | 00:00:00:00:00:32 | 192.168.40.32  |
   | k8s-node-3      | 00:00:00:00:00:33 | 192.168.40.33  |
   | test-k8s-vip    | N/A               | 192.168.40.220 |
   | test-k8s-cp-1   | 00:00:00:00:02:21 | 192.168.40.221 |
   | test-k8s-cp-2   | 00:00:00:00:02:22 | 192.168.40.222 |
   | test-k8s-cp-3   | 00:00:00:00:02:23 | 192.168.40.223 |
   | test-k8s-node-1 | 00:00:00:00:02:31 | 192.168.40.231 |
   | test-k8s-node-2 | 00:00:00:00:02:32 | 192.168.40.232 |
   | test-k8s-node-3 | 00:00:00:00:02:33 | 192.168.40.233 |

6. Create and select a workspace for your Terraform state. Or configure a different backend accordingly.
   ```bash
   terraform workspace new test
   ```

7. Initialize Terraform and create the cluster

   ```bash
   terraform init
   terraform apply
   ```

8. Retrieve the Kubernetes and Talos configuration files. 
   ```bash
   mkdir -p ~/.{kube,talos}
   terraform output -raw kubeconfig > ~/.kube/config
   terraform output -raw talosconfig > ~/.talos/config
   ```

9. Confirm Kubernetes is bootstrapped and all of the nodes have joined the cluster. The Controlplane nodes might take a moment to respond. You can confirm the status of each Talos node using `talosctl` or by reviewing the VM consoles in Proxmox.
   ```bash
   watch kubectl get nodes,all -A
   ```

10. Upgrade the nodes to enable QEMU Guest Agent. If you run this too soon, etcd won't be ready and the control planes will fail to upgrade. 
   ```bash
   NODES=$(kubectl get nodes --no-headers=true | awk '{print $1}' | tr '\n' ',')
   ./bin/manage_nodes $NODES upgrade
   ```

11. Use Kubernetes as you see fit. You can find my personal collection of manifests [here](https://github.com/zimmertr/Application-Manifests). 



