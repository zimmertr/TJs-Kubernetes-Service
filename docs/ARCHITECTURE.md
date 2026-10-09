# Architecture

## What TKS creates

| File | Creates |
| --- | --- |
| `talos_resource_pool.tf` | A Proxmox resource pool that holds the cluster's VMs |
| `talos_image.tf` | A Talos Image Factory schematic (from `configs/talos_image_factory.yml`) and the `nocloud` disk image on a Proxmox datastore. The image is downloaded under an `.iso` name, because Proxmox will not store `.xz`, then renamed and unpacked over SSH |
| `talos_controlplanes.tf` | One VM for each control plane, cloned from the image, plus its Talos machine configuration |
| `talos_workernodes.tf` | One VM for each worker, the same way |
| `talos_cluster.tf` | Talos machine secrets, the bootstrap of the first control plane, and the `kubeconfig` and `talosconfig` outputs |

## How a node comes up

1. Terraform creates the VM with a fixed MAC address, and the network's DHCP server hands it the reserved IP.
2. Talos boots from the image in maintenance mode.
3. Terraform applies the machine configuration to the node's IP. The patches in `configs/` set the installer image, KubePrism, kubelet certificate rotation, and the control planes' shared virtual IP.
4. The first control plane is bootstrapped, and the others join through the virtual IP.

## Removing a node

A destroy-time provisioner runs `bin/manage_nodes remove`, which resets the node with `talosctl` and deletes it from Kubernetes.
