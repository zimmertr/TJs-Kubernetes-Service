# TJ's Kubernetes Service

* [Summary](#summary)
* [Requirements](#requirements)
* [Instructions](#instructions)
* [Post Install](#post-install)
  * [Installing QEMU Guest Agent](#installing-qemu-guest-agent)
  * [Installing A Different CNI](#installing-a-different-cni)
  * [Scaling the Cluster](#scaling-the-cluster)
  * [Installing Other Apps](#installing-other-apps)

* [Troubleshooting](#troubleshooting)
  * [Terraform is Stuck Deleting](#terraform-is-stuck-deleting)


<hr>

## Summary

TJ's Kubernetes Service, or *TKS*, is an IaC project that is used to deliver Kubernetes to Proxmox. Across the years, it has evolved many times and has used a multitude of different technologies. Nowadays, it is a relatively simple collection of Terraform manifests thanks to the work of [BPG](https://github.com/bpg/terraform-provider-proxmox) and [Sidero Labs](https://github.com/siderolabs/terraform-provider-talos).

<hr>

## Requirements

| Requirement  | Description                                                  |
| ------------ | ------------------------------------------------------------ |
| `terraform`  | Used for creating the cluster                                |
| `kubectl`    | Used for *upgrading* the Talos nodes to install QEMU Guest Agent and removing nodes from the cluster |
| `talosctl`   | Used for *upgrading* the Talos nodes to install QEMU Guest Agent and removing nodes from the cluster |
| `ssh-agent`  | Used for connecting to the Proxmox server to bootstrap the Talos image |
| Proxmox      | You already know                                             |
| DNS Resolver | Used for configuring DHCP reservation during cluster creation and DNS resolution within the cluster |

<hr>

## Instructions

1. Configure SSH access with a private key to your Proxmox server. This is needed to provision the installation image and also for [certain API actions](https://registry.terraform.io/providers/bpg/proxmox/latest/docs#api-token-authentication) executed by the Terraform provider.

2. Create an API token on Proxmox. I personally use [this Ansible role](https://github.com/zimmertr/Bootstrap-Proxmox/blob/master/roles/configure_terraform_user/tasks/main.yml).

3. Add your SSH key to `ssh-agent`:

   ```bash
   eval "$(ssh-agent -s)"
   ssh-add --apple-use-keychain ~/.ssh/sol.Milkyway
   ```

4. Set the environment variables required to authenticate to your Proxmox server according to the provider [docs](https://registry.terraform.io/providers/bpg/proxmox/latest/docs#authentication).  I personally use an API Token and define them in `vars/config.env`. Source them into your shell.

   ```bash
   source vars/config.env
   ```

5. Review `variables.tf` and set any overrides according to your environment in a new [tfvars](https://developer.hashicorp.com/terraform/language/values/variables#variable-definitions-tfvars-files) file.

6. Create DNS records and DHCP reservations for your nodes according to your configured Hostname, MAC address, and IP Address prefixes. Due to the way the values are generated in Terraform, there is a limit of 9 control planes and 9 worker nodes. Here is how mine is configured for two clusters:

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

7. Initialize Terraform and create a workspace for your Terraform state. Or configure a different backend accordingly.

   ```bash
   terraform init
   terraform workspace new test
   ```

8. Create the cluster

   ```bash
   terraform apply --var-file="vars/test.tfvars"
   ```

9. Retrieve the Kubernetes and Talos configuration files. Be sure not to overwrite any existing configs you wish to preserve. I use [kubecm](https://github.com/sunny0826/kubecm) to add/merge configs and [kubectx](https://github.com/ahmetb/kubectx) to change contexts.

   ```bash
   mkdir -p ~/.{kube,talos}
   touch ~/.kube/config

   terraform output -raw talosconfig > ~/.talos/config-test
   terraform output -raw kubeconfig > ~/.kube/config-test

   kubecm add -f ~/.kube/config-test
   kubectx admin@test
   ```

10. Confirm Kubernetes is bootstrapped and that all of the nodes have joined the cluster. The Controlplane nodes might take a moment to respond. You can confirm the status of each Talos node using `talosctl` or by reviewing the VM consoles in Proxmox.

    ```bash
    watch kubectl get nodes,all -A
    ```

<hr>

## Post Install

## Installing QEMU Guest Agent

Talos installs the QEMU Guest Agent, but it won't be enabled until the nodes are _upgraded_. Once everything in the cluster has become `Ready`, upgrade the nodes using `talosctl` or the `manage_nodes` script. If you opted to disable Flannel, you need to install a CNI before this will work.

```bash
NODES=$(kubectl get nodes --no-headers=true | awk '{print $1}' | tr '\n' ',')
./bin/manage_nodes upgrade $NODES
```

<hr>

## Installing A Different CNI

By default, Talos uses Flannel. To use a different CNI make sure that `var.talos_disable_flannel` is set to `true` during provisioning. The cluster will not be functional and you will not be able to _upgrade_ the nodes to install QEMU Guest Agent until a CNI is enabled. Cilium can be installed using the following two Kustomizations:

| Project                                                      | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [cilium](https://github.com/zimmertr/Kubernetes-Manifests/tree/main/core/cilium) | The Cilium CNI                                               |
| [kubelet-csr-approver](https://github.com/zimmertr/Kubernetes-Manifests/tree/main/core/kubelet-csr-approver) | A [project](https://github.com/postfinance/kubelet-csr-approver) to automatically approve Certificate Signing Requests |

<hr>

## Scaling the Cluster

The Terraform provider makes it quite easy to scale in, out, up, or down. Simply adjust the variables for resources or desired number of nodes and run `terraform plan` again. If the plan looks. good, apply it.

In the event you scale down a node, terraform will execute a local-provisioner that runs the following command to remove the node from the cluster for you as well:

```bash
./bin/manage_nodes remove $NODE
```

Considerations:

* As QEMU Guest Agent's installation is not managed by Terraform, be sure to run `./bin/manage_nodes upgrade $NODE` against any new nodes that are added to enable it. Otherwise, Terraform will have issues interacting with it through the Proxmox API.
* At this time I don't think it's possible to choose a specific node to remove. You must scale up and down the last node.
* Due to the way I configure IP Addressing using DHCP reservations, there is a limit of both 9 controlplanes and 9 workernodes.

<hr>

## Installing Other Apps

You can find my personal collection of manifests [here](https://github.com/zimmertr/Application-Manifests).

<hr>

## Troubleshooting

### Terraform is Stuck Deleting

Proxmox won't be able to issue a shutdown signal to the virtual machines unless QEMU Guest Agent is enabled. This can lead to Terraform trying to destroy nodes unsuccessfully until the API times out the command. In the event this occurs, you can work connect to Proxmox manually and remove the VMs, then proceed with `terraform destroy` as usual. For example:

```bash
ssh -i ~/.ssh/sol.milkyway root@earth.sol.milkyway "rm /var/lock/qemu-server/lock-*; qm list | grep 40 | awk '{print \$1}' | xargs -L1 qm stop && sleep 5 && qm list | grep 40 | awk '{print \$1}' | xargs -L1 qm destroy"
```
