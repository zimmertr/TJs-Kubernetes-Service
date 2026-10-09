# Usage

This page describes the v1 layout on `main` today. v2 replaces it ([epic #63](https://github.com/zimmertr/TJs-Kubernetes-Service/issues/63)).

## Build a cluster

1. Set up SSH access to the Proxmox host with a private key, and add the key to `ssh-agent`. The provider needs SSH for [some API actions](https://registry.terraform.io/providers/bpg/proxmox/latest/docs#api-token-authentication), and TKS uses it to unpack the Talos image.

   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/<your-proxmox-key>
   ```

2. Create a Proxmox API token ([`SECURITY_GUIDE.md`](SECURITY_GUIDE.md)). Copy `vars/config.env.example` to `vars/config.env`, fill in the token, and source it:

   ```bash
   source vars/config.env
   ```

3. Copy one of the example tfvars files in `vars/` and set your values. [`CONFIGURATION.md`](CONFIGURATION.md) lists every variable.

4. Create a DHCP reservation and a DNS record for each node. Each node's MAC address and IP come from a prefix plus the node's number. For example, with `controlplane_mac_address_prefix = "00:00:00:00:00:1"` and `controlplane_ip_prefix = "192.168.40.1"`:

   | Hostname | MAC address | IP address |
   | --- | --- | --- |
   | k8s-cp-1 | 00:00:00:00:00:11 | 192.168.40.11 |
   | k8s-cp-2 | 00:00:00:00:00:12 | 192.168.40.12 |
   | k8s-node-1 | 00:00:00:00:00:21 | 192.168.40.21 |

5. Initialize Terraform, create a workspace for the cluster's state, and apply:

   ```bash
   terraform init
   terraform workspace new test
   terraform apply -var-file=vars/test.tfvars
   ```

6. Export the Kubernetes and Talos configs, taking care not to overwrite configs you want to keep:

   ```bash
   mkdir -p ~/.kube ~/.talos
   terraform output -raw talosconfig > ~/.talos/config-test
   terraform output -raw kubeconfig > ~/.kube/config-test
   ```

7. Confirm every node joined. Control planes can take a moment to respond:

   ```bash
   kubectl --kubeconfig ~/.kube/config-test get nodes
   ```

8. Kubernetes approves kubelet serving-certificate requests on its own only for standard node names. With custom hostnames, review and approve them:

   ```bash
   kubectl get csr
   kubectl get csr -o name | xargs kubectl certificate approve
   ```

## Use a different CNI

Talos uses Flannel by default. Set `talos_disable_flannel = true` to disable Flannel and kube-proxy, then install another CNI such as Cilium. Until a CNI is running, the cluster is not functional and its nodes cannot be upgraded. Installing [kubelet-csr-approver](https://github.com/postfinance/kubelet-csr-approver) saves approving certificate requests by hand.

## Expose control-plane metrics

Talos binds the metrics endpoints for etcd, the scheduler, the controller-manager and kube-proxy to localhost, so a monitoring stack cannot scrape them. Set `talos_expose_metrics = true` to bind them to the node addresses instead. The scheduler and controller-manager still require TLS and RBAC. etcd's listener (`2381`) and kube-proxy's (`10249`) are plain HTTP and readable by anything that can reach the node network, which is why this is off by default.

On a running cluster, the scheduler, the controller-manager and the API server pick the change up when the configuration is applied. etcd does not, because Talos refuses API-driven etcd restarts: reboot each control plane one at a time with `talosctl -n <node> reboot`, checking `talosctl etcd status` between nodes. kube-proxy only re-renders on `talosctl upgrade-k8s --to <current version>`.

## Scale the cluster

Change the node counts or sizes in your tfvars and apply. When a node is removed, Terraform runs `bin/manage_nodes remove <node>` to reset it and delete it from Kubernetes. Only the highest-numbered node of a pool can be removed, and each pool is limited to nine nodes by the addressing scheme.

## Troubleshooting

### Terraform hangs while destroying nodes

If the QEMU guest agent isn't working, Proxmox can hang when it asks a VM to shut down, and Terraform waits until the API times out. Stop and destroy the VMs from the Proxmox host (`qm stop <vmid>`, then `qm destroy <vmid>`), and run `terraform destroy` again.
