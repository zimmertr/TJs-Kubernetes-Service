# Architecture

## What TKS creates

One Terraform root builds one cluster. Use a workspace (or a separate state) per cluster.

| File | Creates |
| --- | --- |
| `cluster.tf` | The Proxmox resource pool, the Talos machine secrets, the `talos_cluster` that bootstraps etcd and upgrades Kubernetes, and the `kubeconfig` and `talosconfig` outputs |
| `nodes.tf` | The node pools, by calling the modules below. It renders each node's Talos patches from `configs/` |
| `modules/talos_image` | A Talos Image Factory schematic and its `nocloud` `qcow2` image, downloaded to a Proxmox datastore as `tks-<cluster>-<pool>-<version>.qcow2` |
| `modules/node` | For each node in a pool: the VM, its Talos machine configuration, and the `talos_machine` that applies and upgrades it |
| `bootstrap/` | Optional, and a separate root. The Proxmox role, user and API token TKS runs as |

## How a node comes up

1. Terraform creates the VM with its disk imported from the pool's image. Cloud-init gives it its static IP, gateway and DNS servers.
2. Talos boots in maintenance mode.
3. `talos_machine` applies the machine configuration to the node's IP. The patches in `configs/` set the installer image, the hostname, and the control planes' shared virtual IP, plus Flannel and metrics settings when they are switched on.
4. `talos_cluster` bootstraps etcd on the first control plane, and the others join through the virtual IP.

Control planes come up before workers.

## Upgrades

Nothing in an upgrade replaces a VM. The VM reads its image only when it is created.

- **Talos.** A new `talos_version` downloads a new image and changes the installer image. `talos_machine` drains each node and upgrades it in place. Applies run with `-parallelism=1`, so nodes upgrade one at a time, control planes first.
- **Kubernetes.** A new `kubernetes_version` makes `talos_cluster` run Talos's `upgrade-k8s`, which checks the cluster's health as it goes.

`talos_config_version` is different from `talos_version`. It fixes the shape of the generated configuration and is set once when the cluster is created. The machine secrets keep the version they were created with, because replacing them would regenerate the cluster's certificates.

## Removing a node

Delete it from the tfvars and apply. `talos_machine` resets the node first, so it leaves etcd and Kubernetes, and then the VM is destroyed. Workers are removed before control planes.
