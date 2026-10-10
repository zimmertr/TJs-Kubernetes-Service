# TJ's Kubernetes Service

* [Summary](#summary)
* [Requirements](#requirements)
* [Instructions](#instructions)
* [Configuration Options](#configuration-options)
  * [Storing State in HCP Terraform](#storing-state-in-hcp-terraform)
  * [Using a Different CNI](#using-a-different-cni)
  * [Using a Cloud Controller Manager](#using-a-cloud-controller-manager)
  * [Exposing Control Plane Metrics](#exposing-control-plane-metrics)
  * [Adding a GPU Worker](#adding-a-gpu-worker)
* [Managing the Cluster](#managing-the-cluster)
* [Documentation](#documentation)


<hr>

## Summary

TJ's Kubernetes Service, or *TKS*, is a collection of Terraform configurations that deploy [Talos Linux](https://www.talos.dev) Kubernetes clusters to Proxmox VE, using the [BPG Proxmox](https://github.com/bpg/terraform-provider-proxmox) and [Sidero Labs Talos](https://github.com/siderolabs/terraform-provider-talos) providers.

<hr>

## Requirements

| Requirement | Description                                                                                                                                                                              |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `terraform` | Creates and manages the cluster. Version 1.16 or newer                                                                                                                                   |
| `kubectl`   | Used by `manage_nodes`                                                                                                                                                                   |
| `talosctl`  | Used by `manage_nodes`                                                                                                                                                                   |
| `jq`        | Used by `manage_nodes` and to read the bootstrap tokens                                                                                                                                  |
| Proxmox VE  | A host or cluster to run the nodes on                                                                                                                                                    |
| IOMMU       | Only for a [GPU worker](#adding-a-gpu-worker). Enabled on the host, with each GPU alone in its IOMMU group. Binding the GPUs to `vfio-pci` at boot keeps the host from initializing them |

<hr>

## Instructions

1. If you don't already have one, create a Proxmox API token for the Terraform provider to use. The [bootstrap](bootstrap) Terraform root can be used to create the users listed in [`vars/bootstrap.tfvars`](vars/bootstrap.tfvars), each of which comes with its own role and token. 

   The example file defines a user with only the privileges TKS needs (listed in the [Security](docs/SECURITY_GUIDE.md#the-proxmox-user) guide), plus users for the [Proxmox CSI Plugin](https://github.com/sergelogvinov/proxmox-csi-plugin) and the [Proxmox Cloud Controller Manager](https://github.com/sergelogvinov/proxmox-cloud-controller-manager). 

   The bootstrap root needs root credentials, so export them in a separate shell used only for this step:

   ```bash
# The provider prefers a token over a password, so ensure it won't interfere if it's set
   unset PROXMOX_VE_API_TOKEN 
   
   export PROXMOX_VE_ENDPOINT="https://earth.sol.milkyway:8006"
   export PROXMOX_VE_INSECURE="true"
   export PROXMOX_VE_USERNAME="root@pam"
   export PROXMOX_VE_PASSWORD="REPLACEME"
   
   cd bootstrap
   terraform init
   terraform apply -var-file=../vars/bootstrap.tfvars
   terraform output -json api_tokens | jq
   ```
   
   After running `terraform output`, each user's token is printed as `<id>=<secret>`. 

2. Copy [`vars/config.env.example`](vars/config.env.example) to `vars/config.env`, configure it, and source it as per the provider's [documentation](https://registry.terraform.io/providers/bpg/proxmox/latest/docs#authentication). 

   ```bash
   source vars/config.env
   ```

3. Create a [tfvars](https://developer.hashicorp.com/terraform/language/values/variables#variable-definitions-tfvars-files) file for the cluster. Every input is described in [Configuration](docs/CONFIGURATION.md), and [`vars/test.tfvars`](vars/test.tfvars) is a complete example. Nodes are a map keyed by hostname, each with a static IP and VMID. 

4. Initialize Terraform and create a workspace for the cluster. 

   ```bash
   terraform init
   terraform workspace new tks-test
   ```

5. Create the cluster:

   ```bash
   terraform apply --var-file="vars/test.tfvars"
   ```

6. Retrieve the Kubernetes and Talos configuration files, taking care not to overwrite existing ones. [kubecm](https://github.com/sunny0826/kubecm) and [kubectx](https://github.com/ahmetb/kubectx) can merge kubeconfigs and switch contexts.

   ```bash
   mkdir -p ~/.{kube,talos}
   touch ~/.kube/config
   
   terraform output -raw talosconfig > ~/.talos/config-test
   terraform output -raw kubeconfig > ~/.kube/config-test
   
   kubecm add -f ~/.kube/config-test
   kubectx admin@test
   ```

7. Confirm that Kubernetes is bootstrapped and that every node has joined. The control plane can take a moment to respond. Each node's status is also visible through `talosctl` or the VM console in Proxmox.

   ```bash
   watch kubectl get nodes,all -A
   ```

8. Kubelet serving certificates require their certificate signing requests (CSRs) to be approved. Without an approver such as [Kubelet CSR Approver](https://github.com/postfinance/kubelet-csr-approver), review and approve them manually:

   ```bash
   # Review pending CSRs to validate they are as expected
   kubectl get csr
   kubectl describe csr csr-foobar
   
   # Approve all pending CSRs
   kubectl get csr -o name | xargs kubectl certificate approve
   ```

<hr>

## Configuration Options

### Storing State in HCP Terraform

Both Terraform roots store state locally by default. State holds the cluster's secrets and, for the bootstrap root, the Proxmox API tokens; the [Security](docs/SECURITY_GUIDE.md#secrets-in-terraform-state) guide covers keeping it safe. To store it in [HCP Terraform](https://app.terraform.io) instead, complete these steps before the first `terraform init` in each root:

1. In the HCP Terraform organization, set the *Default Execution Mode* to *Local* under *Settings > General*, so plans run locally where Proxmox is reachable.
2. Run `terraform login`.
3. Copy `cloud_override.tf.example` to `cloud_override.tf`, and `bootstrap/cloud_override.tf.example` to `bootstrap/cloud_override.tf`, and set the organization in both.

The bootstrap root uses a workspace named `tks-bootstrap`. Cluster workspaces are tagged `tks-cluster`, and HCP Terraform uses each workspace's name as is, so a `tks-` prefix is recommended. The first `terraform init` in the repository root prompts for a workspace name, because no workspace has the tag yet; enter the cluster's workspace name there instead of running `terraform workspace new`. If a root already has local state, `terraform init` offers to migrate it.

### Using a Different CNI

Talos uses Flannel by default. To use a different CNI, set `cluster.disable_flannel` to `true` when the cluster is created. The cluster is not functional, and nodes cannot be upgraded, until a CNI is installed.

### Using a Cloud Controller Manager

Set `cluster.external_cloud_provider` to `true` to hand node initialization and cleanup to a cloud controller manager such as the [Proxmox CCM](https://github.com/sergelogvinov/proxmox-cloud-controller-manager). It sets each node's `providerID` and its `topology.kubernetes.io/zone` and `region` labels, and deletes a node from Kubernetes once its VM is gone. The CCM is deployed separately; an example deployment, including where it fits in a cluster's bootstrap order, is available in [Kubernetes-Manifests](https://github.com/zimmertr/Kubernetes-Manifests/tree/main/misc/proxmox-cloud-controller-manager). Its Proxmox user is defined in [`vars/bootstrap.tfvars`](vars/bootstrap.tfvars).

New nodes join with the `node.cloudprovider.kubernetes.io/uninitialized` taint and keep it until the CCM initializes them. Flannel, CoreDNS and kube-proxy tolerate the taint, but other workloads do not schedule, so install the CCM first.

Enable it when the cluster is created where possible. Nodes that joined before it was enabled are ignored by the CCM until they register again; see `manage_nodes reregister` under [Managing the Cluster](#managing-the-cluster).

### Exposing Control Plane Metrics

Talos binds the metrics endpoints for etcd, the scheduler, the controller-manager and kube-proxy to localhost, so a monitoring stack such as kube-prometheus-stack cannot scrape them. Set `cluster.expose_metrics` to `true` to bind them to the node addresses instead. The scheduler and controller-manager still authenticate scrapes with TLS and RBAC, but the etcd (`2381`) and kube-proxy (`10249`) listeners are plain HTTP and readable from the node network, which is why this is opt-in.

On a running cluster, the scheduler, controller-manager and API server apply the change on their own. etcd does not, because Talos refuses API-driven etcd restarts: reboot the control plane nodes with [`manage_nodes reboot`](#managing-the-cluster), naming each of them. It restarts them one at a time and waits for etcd before moving to the next. kube-proxy is a bootstrap manifest and only re-renders on `talosctl upgrade-k8s --to $CURRENT_VERSION`.

### Adding a GPU Worker

Set `gpu_workers` to add worker nodes that each have a GPU from the Proxmox host passed through. Each node names its GPU by the PCI address `lspci` shows for it, so identical cards are told apart:

```hcl
gpu_workers = {
  nodes = {
    "k8s-node-gpu-1" = { ip = "192.168.40.31", vm_id = 4031, cores = 16, memory_mb = 196608, pci_address = "05:00.0" }
    "k8s-node-gpu-2" = { ip = "192.168.40.32", vm_id = 4032, cores = 16, memory_mb = 196608, pci_address = "06:00.0" }
  }
}
```

TKS reads the rest of what it needs about each card from the Proxmox API, and creates a PCI resource mapping named `<cluster>-<hostname>-gpu` that holds only that card. The plan fails if nothing is at an address, if a card has no IOMMU group, or if two nodes name the same card. If a card moves to another slot, set its new address and apply again. GPU nodes are built from their own Talos image with the `siderolabs/amdgpu` extension.

GPU nodes carry the `amd.com/gpu:NoSchedule` taint and the `tks.io/pool=gpu` label. Every TKS cluster enables the `ExtendedResourceToleration` admission plugin, so pods that request `amd.com/gpu` get the matching toleration without declaring it. Anything else that should run on a GPU node needs its own toleration, including the AMD device plugin that advertises `amd.com/gpu` to Kubernetes, which is deployed separately.

Proxmox starts only one VM per card, so two clusters on the same host cannot run GPU nodes with the same card at once.

<hr>

## Managing the Cluster

Scaling and upgrades are driven by the tfvars file. Add, remove or resize nodes, or change `talos_version` or `kubernetes_version`, then run `terraform plan` and apply. Upgrades happen in place, one node at a time with control planes first; nodes are drained before a Talos upgrade, and Kubernetes upgrades are health checked. Renovate opens pull requests for new versions and checks that the Talos and Kubernetes versions are compatible. `talos_config_version` stays at the version the cluster was created with, as described in step 3 of the [Instructions](#instructions).

Some operations need more than an apply. [`bin/manage_nodes`](bin/manage_nodes) handles them, one node at a time, from the repository root in the cluster's workspace after `source vars/config.env`:

| Command                       | Use                                                          |
| ----------------------------- | ------------------------------------------------------------ |
| `remove NODE`                 | Takes a node out of the cluster: drains it, removes it from etcd if it is a control plane, resets it and deletes it from Kubernetes. Run it before removing the node from the tfvars. If it runs afterwards, it removes the dead etcd member instead, which requires at least three control planes. It refuses to remove the last control plane. With a cloud controller manager, workers can be removed with only the apply, but draining first is still recommended |
| `reboot [NODE...]`            | Restarts nodes through Proxmox after a change to cores, memory or PCI devices, which Terraform does not apply to running VMs. Each node is drained, restarted, and waited on before the next |
| `reregister [NODE...]`        | Registers nodes again after `cluster.external_cloud_provider` is enabled on an existing cluster. Each node is drained, deleted from Kubernetes, rebooted onto its new pod network, and waited on until the CCM has initialized it. Needed once per cluster |

Without node names, `reboot` and `reregister` process every node, control planes first.

```bash
./bin/manage_nodes remove k8s-node-3
./bin/manage_nodes reboot
./bin/manage_nodes reregister k8s-node-2 k8s-node-3
```

<hr>

## Documentation

More detailed documentation can be found in the [docs](docs) directory:

| Document                                    | Description                                                   |
| ------------------------------------------- | ------------------------------------------------------------- |
| [Configuration](docs/CONFIGURATION.md)      | Every input variable, generated from the code                 |
| [Architecture](docs/ARCHITECTURE.md)        | What TKS creates and how it fits together                     |
| [Security](docs/SECURITY_GUIDE.md)          | Credentials, secrets in Terraform state, and scanning         |
| [CI/CD](docs/CICD.md)                       | Checks, releases, and dependency updates                      |
| [Decisions](docs/decisions/README.md)       | Architectural decision records explaining why TKS is built the way it is |
| [Contributing](CONTRIBUTING.md)             | How to propose a change                                       |
