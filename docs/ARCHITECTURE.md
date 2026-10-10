# Architecture

## What TKS creates

One Terraform root builds one cluster. Use a workspace (or a separate state) per cluster.

| File | Creates |
| --- | --- |
| `cluster.tf` | The Proxmox resource pool, the Talos machine secrets, the `talos_cluster` that bootstraps etcd and upgrades Kubernetes, and the `kubeconfig` and `talosconfig` outputs |
| `nodes.tf` | The node pools, by calling the modules below. It renders each node's Talos patches from `configs/` |
| `modules/talos_image` | A Talos Image Factory schematic and its SecureBoot `nocloud` `qcow2` image, downloaded to a Proxmox datastore as `tks-<cluster>-<pool>-<version>.qcow2` |
| `modules/node` | For each node in a pool: the VM, its Talos machine configuration, and the `talos_machine` that applies and upgrades it |
| `modules/gpu_worker` | Optional. Looks up the host's GPU, creates the `<cluster>-gpu` PCI resource mapping for it, and builds the GPU nodes through `modules/node` with the mapping attached |
| `modules/pci_device` | Chooses one device from the PCI lookup and turns it into a mapping entry. It fails the plan unless exactly one device matches, or if that device has no IOMMU group |
| `bootstrap/` | Optional, and a separate root. A Proxmox role, user and API token for each user in its `users` map, such as the one TKS runs as |

## How a node comes up

1. Terraform creates the VM with its disk imported from the pool's image. Cloud-init gives it its static IP, gateway and DNS servers. Without `network.dns_servers`, Proxmox supplies its host's resolvers.
2. On first boot, the image enrolls Talos's SecureBoot keys, because the VM's UEFI starts with none. Talos then boots in maintenance mode.
3. `talos_machine` applies the machine configuration to the node's IP. The patches in `configs/` set the installer image, the hostname, and the control planes' shared virtual IP, plus Flannel, metrics and external cloud provider settings when they are switched on.
4. `talos_cluster` bootstraps etcd on the first control plane, and the others join through the virtual IP.

Control planes come up before workers. GPU nodes are workers built from their own image, with the GPU driver extension, and an extra patch that registers them with the `amd.com/gpu:NoSchedule` taint and the `tks.io/pool=gpu` label. [0002](decisions/0002-gpu-worker-module.md), [0006](decisions/0006-gpu-found-by-class.md), [0017](decisions/0017-gpu-taint-extended-resource-toleration.md)

## Upgrades

Nothing in an upgrade replaces a VM. The VM reads its image only when it is created.

- **Talos.** A new `talos_version` downloads a new image and changes the installer image. `talos_machine` drains each node and upgrades it in place. Applies run with `-parallelism=1`, so nodes upgrade one at a time, control planes first.
- **Kubernetes.** A new `kubernetes_version` makes `talos_cluster` run Talos's `upgrade-k8s`, which checks the cluster's health as it goes.

`talos_config_version` is different from `talos_version`. It fixes the shape of the generated configuration and is set once when the cluster is created. The machine secrets keep the version they were created with, because replacing them would regenerate the cluster's certificates.

## Removing a node

Terraform only deletes a removed node's VM. It doesn't reset the node, so `terraform destroy` of a whole cluster never waits on etcd or on draining. `bin/manage_nodes remove` takes a single node out of the cluster: run before the apply, it drains the node, resets it gracefully (so a control plane leaves etcd) and deletes the Node object. Run after, it removes the dead etcd member from another control plane and deletes the Node object. It refuses to remove the last control plane. With `cluster.external_cloud_provider` on, a cloud controller manager also deletes the Node object of any VM that's gone, so a worker needs nothing more than the apply. `bin/manage_nodes reregister` registers existing nodes again, one at a time, after the switch is turned on, because a cloud controller manager only initializes nodes as they register. [0027](decisions/0027-optional-external-cloud-provider.md), [0028](decisions/0028-manage-nodes-reregister.md)

## Changing a node's hardware

VMs have `reboot_after_update = false`, so a change to cores, memory or PCI devices waits for a restart. `bin/manage_nodes reboot` drains each node, restarts its VM through the Proxmox API (a reboot from inside Talos keeps the old hardware), waits for it to be Ready (and for etcd, on a control plane), and uncordons it, one node at a time.
