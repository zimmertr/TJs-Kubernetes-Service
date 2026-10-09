# Configuration

Every input variable, generated from the code by `make docs`. Set them in a tfvars file under `vars/`, and pass it with `-var-file`. This reference describes the v1 variables on `main` today.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.14.6 |
| http | ~> 3.6 |
| proxmox | ~> 0.116.0 |
| talos | ~> 0.12.0 |

## Providers

| Name | Version |
| ---- | ------- |
| http | 3.6.2 |
| proxmox | 0.116.0 |
| talos | 0.12.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [proxmox_virtual_environment_file.talos_image](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_pool.proxmox_resource_pool](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_pool) | resource |
| [proxmox_virtual_environment_vm.controlplane](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |
| [proxmox_virtual_environment_vm.workernode](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.controlplane](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.workernode](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_secrets) | resource |
| [http_http.talos_schematic](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/client_configuration) | data source |
| [talos_machine_configuration.controlplane](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.workernode](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| controlplane\_ip\_prefix | IP address prefix (less the last digit) of the controlplane nodes | `string` | n/a | yes |
| controlplane\_mac\_address\_prefix | MAC address (less the last digit) of the controlplane nodes | `string` | n/a | yes |
| controlplane\_node\_name | Proxmox node used for provisioning the workernodes | `string` | n/a | yes |
| controlplane\_vmid\_prefix | VMID prefix (less the last digit) of the controlplane nodes | `number` | n/a | yes |
| proxmox\_hostname | IP address or hostname of the Proxmox server | `string` | n/a | yes |
| proxmox\_ssh\_key\_path | Path to an SSH key used to connect to the Proxmox server | `string` | n/a | yes |
| talos\_image\_node\_name | Proxmox node used for storing the Talos image | `string` | n/a | yes |
| talos\_virtual\_ip | Virtual IP address you wish for Talos to use | `string` | n/a | yes |
| workernode\_ip\_prefix | IP address prefix (less the last digit) of the Worker Nodes | `string` | n/a | yes |
| workernode\_mac\_address\_prefix | MAC address (less the last digit) of the workernode nodes | `string` | n/a | yes |
| workernode\_node\_name | Proxmox node used for provisioning the workernodes | `string` | n/a | yes |
| workernode\_vmid\_prefix | The VMID Prefix (less the last digit) of the workernode nodes | `number` | n/a | yes |
| controlplane\_cpu\_cores | Quantity of CPU cores to apply to the controlplane virtual machines | `number` | `4` | no |
| controlplane\_datastore | Datastore used for the controlplane virtual machines | `string` | `"FlashPool"` | no |
| controlplane\_disk\_size | Quantity of disk space (gigabytes) to apply to the controlplane virtual machines | `number` | `"50"` | no |
| controlplane\_hostname\_prefix | Hostname prefix (less the last digit) of the controlplane nodes | `string` | `"k8s-cp"` | no |
| controlplane\_memory | Quantity of memory (megabytes) to apply to the controlplane virtual machines | `number` | `10240` | no |
| controlplane\_network\_device | Network device used for the controlplane virtual machines | `string` | `"vmbr0"` | no |
| controlplane\_num | Quantity of controlplane nodes to provision | `number` | `3` | no |
| controlplane\_tags | Tags to apply to the controlplane virtual machines | `list(string)` | <pre>[<br/>  "app-kubernetes",<br/>  "type-controlplane"<br/>]</pre> | no |
| controlplane\_vlan\_id | VLAN ID used for the controlplane nodes | `number` | `null` | no |
| kubernetes\_cluster\_name | Kubernetes cluster name you wish for Talos to use | `string` | `"kubernetes"` | no |
| kubernetes\_version | Identify here: https://github.com/siderolabs/kubelet/pkgs/container/kubelet | `string` | `"v1.35.2"` | no |
| proxmox\_resource\_pool | Resource Pool to create on Proxmox for the cluster | `string` | `"Kubernetes"` | no |
| proxmox\_username | IP address or hostname of the Proxmox server | `string` | `"root"` | no |
| talos\_disable\_flannel | Whether or not the Flannel CNI & Kube Proxy should be disabled for Cilium | `bool` | `false` | no |
| talos\_expose\_metrics | Whether or not etcd, the scheduler, the controller-manager, and kube-proxy should serve Prometheus metrics on the node addresses instead of localhost | `bool` | `false` | no |
| talos\_image\_datastore | DataStore to use on Proxmox for the Talos image | `string` | `"local"` | no |
| talos\_version | Identify here: https://github.com/siderolabs/talos/releases | `string` | `"v1.12.4"` | no |
| workernode\_cpu\_cores | Quantity of CPU cores to apply to the workernode virtual machines | `number` | `10` | no |
| workernode\_datastore | Datastore used for the workernode virtual machines | `string` | `"FlashPool"` | no |
| workernode\_disk\_size | Quantity of disk space (gigabytes) to apply to the workernode virtual machines | `number` | `"50"` | no |
| workernode\_hostname\_prefix | Hostname prefix (less the last digit) of the workernode nodes | `string` | `"k8s-node"` | no |
| workernode\_memory | Quantity of memory (megabytes) to apply to the workernode virtual machines | `number` | `51200` | no |
| workernode\_network\_device | Network device used for the workernode virtual machines | `string` | `"vmbr0"` | no |
| workernode\_num | Quantity of workernode nodes to provision | `number` | `3` | no |
| workernode\_tags | Tags to apply to the workernode virtual machines | `list(string)` | <pre>[<br/>  "app-kubernetes",<br/>  "type-workernode"<br/>]</pre> | no |
| workernode\_vlan\_id | VLAN ID used for the workernode nodes | `number` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| kubeconfig | n/a |
| talosconfig | n/a |
<!-- END_TF_DOCS -->
