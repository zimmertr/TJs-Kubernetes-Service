# Configuration

Every input variable, generated from the code by `make docs`. Set them in a tfvars file under `vars/`, and pass it with `-var-file`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.16 |
| proxmox | ~> 0.116.0 |
| talos | ~> 0.12.0 |

## Providers

| Name | Version |
| ---- | ------- |
| proxmox | 0.116.0 |
| talos | 0.12.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| controlplanes | ./modules/node | n/a |
| image | ./modules/talos_image | n/a |
| workers | ./modules/node | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [proxmox_virtual_environment_pool.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_pool) | resource |
| [talos_cluster.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/cluster) | resource |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_secrets) | resource |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/client_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| cluster | Cluster identity, versions and feature switches | <pre>object({<br/>    name = string<br/>    vip  = string<br/>    # The installed Talos OS. Renovate bumps it, and changing it upgrades<br/>    # nodes in place.<br/>    talos_version = optional(string, "v1.14.2")<br/>    # The provider's config-generation contract, pinned when the cluster is<br/>    # created. Raising it later changes the generated machine config, not the<br/>    # cluster's secrets.<br/>    talos_config_version = string<br/>    kubernetes_version   = optional(string, "v1.37.1")<br/>    disable_flannel      = optional(bool, false)<br/>    expose_metrics       = optional(bool, false)<br/>    # Hands node initialization and cleanup to a cloud controller manager.<br/>    # Nodes stay tainted until one is running.<br/>    external_cloud_provider = optional(bool, false)<br/>  })</pre> | n/a | yes |
| controlplanes | Control plane nodes keyed by hostname, with defaults any node can override | <pre>object({<br/>    defaults = optional(object({<br/>      cores     = optional(number, 4)<br/>      memory_mb = optional(number, 8192)<br/>      disk_gb   = optional(number, 50)<br/>      tags      = optional(list(string), [])<br/>    }), {})<br/>    nodes = map(object({<br/>      ip        = string<br/>      vm_id     = number<br/>      cores     = optional(number)<br/>      memory_mb = optional(number)<br/>      disk_gb   = optional(number)<br/>      tags      = optional(list(string))<br/>    }))<br/>  })</pre> | n/a | yes |
| network | The network every node is attached to. Node IPs are assigned statically from it through cloud-init | <pre>object({<br/>    cidr        = string<br/>    gateway     = string<br/>    dns_servers = list(string)<br/>    bridge      = optional(string, "vmbr0")<br/>    vlan_id     = optional(number)<br/>  })</pre> | n/a | yes |
| proxmox | Where the cluster runs: the Proxmox node, the datastore for VM disks, the datastore for Talos images (it must allow the Import content type), and the resource pool to create | <pre>object({<br/>    node_name          = string<br/>    datastore_id       = optional(string, "FlashPool")<br/>    image_datastore_id = optional(string, "local")<br/>    resource_pool      = string<br/>  })</pre> | n/a | yes |
| workers | Worker nodes keyed by hostname, with defaults any node can override | <pre>object({<br/>    defaults = optional(object({<br/>      cores     = optional(number, 4)<br/>      memory_mb = optional(number, 8192)<br/>      disk_gb   = optional(number, 50)<br/>      tags      = optional(list(string), [])<br/>    }), {})<br/>    nodes = optional(map(object({<br/>      ip        = string<br/>      vm_id     = number<br/>      cores     = optional(number)<br/>      memory_mb = optional(number)<br/>      disk_gb   = optional(number)<br/>      tags      = optional(list(string))<br/>    })), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| kubeconfig | Admin kubeconfig |
| nodes | Every node's IP, VMID, Proxmox node and role, keyed by hostname. bin/manage\_nodes reads it |
| talosconfig | talosctl config for every node |
<!-- END_TF_DOCS -->
