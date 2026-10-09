# TJ's Kubernetes Service

* [Summary](#summary)
* [Requirements](#requirements)
* [Instructions](#instructions)
* [Post Install](#post-install)
  * [Installing A Different CNI](#installing-a-different-cni)
  * [Scaling the Cluster](#scaling-the-cluster)
  * [Upgrading the Cluster](#upgrading-the-cluster)
  * [Installing Other Apps](#installing-other-apps)
* [Troubleshooting](#troubleshooting)
  * [Terraform Fails to Destroy the Cluster](#terraform-fails-to-destroy-the-cluster)
* [Documentation](#documentation)


<hr>

## Summary

TJ's Kubernetes Service, or *TKS*, is an IaC project that is used to deliver Kubernetes to Proxmox. Across the years, it has evolved many times and has used a multitude of different technologies. Nowadays, it is a relatively simple collection of Terraform manifests thanks to the work of [BPG](https://github.com/bpg/terraform-provider-proxmox) and [Sidero Labs](https://github.com/siderolabs/terraform-provider-talos).

<hr>

## Requirements

| Requirement  | Description                                                  |
| ------------ | ------------------------------------------------------------ |
| `terraform`  | Used for creating the cluster                                |
| `kubectl`    | Used for removing and rebooting nodes |
| `talosctl`   | Used for rebooting nodes |
| `jq`         | Used by `manage_nodes` |
| Proxmox      | You already know                                             |
| DNS Resolver | Used for DNS resolution within the cluster |

<hr>

## Instructions

1. Create an API token on Proxmox. I use the [bootstrap](bootstrap) Terraform root in this repo to create mine. It needs root credentials once and outputs a token with only the privileges TKS needs. See the [Security](docs/SECURITY_GUIDE.md#the-proxmox-user) docs for the list.

   ```bash
   cd bootstrap
   terraform init
   terraform apply
   terraform output -raw api_token
   ```

2. Set the environment variables required to authenticate to your Proxmox server according to the provider [docs](https://registry.terraform.io/providers/bpg/proxmox/latest/docs#authentication).  I personally use an API Token and define them in `vars/config.env`. Source them into your shell. Use [`vars/config.env.example`](vars/config.env.example) as a starting point. It also makes Terraform upgrade one node at a time, without it all of the nodes upgrade at once.

   ```bash
   source vars/config.env
   ```

3. Review `variables.tf` and set any overrides according to your environment in a new [tfvars](https://developer.hashicorp.com/terraform/language/values/variables#variable-definitions-tfvars-files) file. Nodes are a map keyed by hostname, each with a static IP and VMID. [`vars/test.tfvars`](vars/test.tfvars) is a good example. Set `talos_config_version` to the same version as `talos_version` and then leave it alone.

4. Create DNS records for your nodes. IPs are assigned statically, so there's no need for DHCP reservations anymore. Here is how mine is configured for two clusters:

   | Hostname        | IP Address    |
   | --------------- | ------------- |
   | k8s-vip         | 192.168.40.10 |
   | k8s-cp-1        | 192.168.40.11 |
   | k8s-cp-2        | 192.168.40.12 |
   | k8s-cp-3        | 192.168.40.13 |
   | k8s-node-1      | 192.168.40.21 |
   | k8s-node-2      | 192.168.40.22 |
   | k8s-node-3      | 192.168.40.23 |
   | test-k8s-vip    | 192.168.40.50 |
   | test-k8s-cp-1   | 192.168.40.51 |
   | test-k8s-node-1 | 192.168.40.61 |

5. Initialize Terraform and create a workspace for your Terraform state. Or configure a different backend accordingly. If you want to use HCP Terraform, copy `cloud_override.tf.example` to `cloud_override.tf`.

   ```bash
   terraform init
   terraform workspace new test
   ```

6. Create the cluster

   ```bash
   terraform apply --var-file="vars/test.tfvars"
   ```

7. Retrieve the Kubernetes and Talos configuration files. Be sure not to overwrite any existing configs you wish to preserve. I use [kubecm](https://github.com/sunny0826/kubecm) to add/merge configs and [kubectx](https://github.com/ahmetb/kubectx) to change contexts.

   ```bash
   mkdir -p ~/.{kube,talos}
   touch ~/.kube/config

   terraform output -raw talosconfig > ~/.talos/config-test
   terraform output -raw kubeconfig > ~/.kube/config-test

   kubecm add -f ~/.kube/config-test
   kubectx admin@test
   ```

8. Confirm Kubernetes is bootstrapped and that all of the nodes have joined the cluster. The Controlplane nodes might take a moment to respond. You can confirm the status of each Talos node using `talosctl` or by reviewing the VM consoles in Proxmox.

   ```bash
   watch kubectl get nodes,all -A
   ```

9. Kubernetes will only automatically approve certificate signing requests (CSRs) if your nodes use a standard FQDN that matches the cluster’s expected domain. If your nodes have custom or non-standard hostnames, you may need to manually review and approve CSRs to complete cluster bootstrapping:

   ```bash
   # Review pending CSRs to validate they are as expected
   kubectl get csr
   kubectl describe csr csr-foobar

   # Approve all pending CSRs
   kubectl get csr -o name | xargs kubectl certificate approve
   ```

<hr>

## Post Install

## Installing A Different CNI

By default, Talos uses Flannel. To use a different CNI make sure that `cluster.disable_flannel` is set to `true` during provisioning. The cluster will not be functional and you will not be able to _upgrade_ the nodes until a CNI is enabled. Cilium can be installed using my project found [here](https://github.com/zimmertr/Kubernetes-Manifests/tree/main/cilium). You will also likely want to install Kubelet CSR Approver to automatically accept the required certificate signing requests. Alternatively, after installing you can accept them manually:

```bash
kubectl get csr
kubectl certificate approve $CSR
```

## Exposing Control Plane Metrics

By default, Talos binds the metrics endpoints for etcd, the scheduler, the controller-manager, and kube-proxy to localhost, so a monitoring stack like [kube-prometheus-stack](https://github.com/zimmertr/Kubernetes-Manifests/tree/main/observability) cannot scrape them. Set `cluster.expose_metrics` to `true` to bind them to the node addresses instead. The scheduler and controller-manager still authenticate scrapes with TLS and RBAC; etcd's metrics listener (`2381`) and kube-proxy's (`10249`) are plain HTTP, readable by anything that can reach the node network, which is why this is opt-in.

On a running cluster, the scheduler, controller-manager, and API server pick the change up on their own when the configuration is applied. etcd does not: Talos refuses API-driven etcd restarts, so reboot each control plane node one at a time with `talosctl -n $NODE reboot`, verifying `talosctl etcd status` between nodes. kube-proxy is a bootstrap manifest and only re-renders on `talosctl upgrade-k8s --to $CURRENT_VERSION`.


<hr>

## Scaling the Cluster

The Terraform provider makes it quite easy to scale in, out, up, or down. Simply add, remove, or resize nodes in your tfvars and run `terraform plan` again. If the plan looks good, apply it.

When you remove a node, Talos drains and resets it first so it leaves etcd cleanly, then Terraform deletes the VM. You can remove any node, not just the last one. Kubernetes doesn't clean up the node object on its own, so remove it afterwards with [manage_nodes](bin/manage_nodes):

```bash
./bin/manage_nodes remove $NODE
```

When you change the CPU, memory, or PCI devices of a node, Proxmox needs to restart the VM for it to take effect. Terraform won't do that for you, otherwise it would restart every node at once. Instead, roll through them one at a time with `manage_nodes`. It drains each node, restarts it from Proxmox, and waits for it to come back before moving on. Controlplanes go first. You can also pass specific nodes.

```bash
./bin/manage_nodes reboot
./bin/manage_nodes reboot $NODE
```

<hr>

## Upgrading the Cluster

Bump `talos_version` or `kubernetes_version` in your tfvars and apply. Nodes are upgraded in place, one at a time, control planes first. Talos nodes are drained before they're upgraded and Kubernetes upgrades are health checked as they go. Renovate opens PRs for new versions in this repo and checks that the Talos and Kubernetes versions are compatible.

Don't change `talos_config_version`. It's fixed when the cluster is created.

<hr>

## Installing Other Apps

You can find my personal collection of manifests [here](https://github.com/zimmertr/Application-Manifests).

<hr>

## Troubleshooting

### Terraform Fails to Destroy the Cluster

Each node is reset before it's deleted so that it leaves the cluster. When you destroy the whole cluster, the last controlplane has no one left to hand etcd to and the reset fails with `not enough started members`. Before you destroy a cluster, set `reset_on_destroy = false` in your `cluster` variable and apply it. Then run `terraform destroy` as usual.

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
