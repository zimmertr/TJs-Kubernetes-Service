# Proxmox
variable "proxmox_hostname" {
  # The Talos image is distributed as an XZ archive and the Proxmox API does not allow you to
  # upload an image with that file format. A remote-exec SSH provisoner is used to manage the
  # image in talos_image.tf.
  type        = string
  description = "IP address or hostname of the Proxmox server"
}
variable "proxmox_username" {
  # A remote-exec SSH provisoner is used to download the image in talos_image.tf.
  type        = string
  default     = "root"
  description = "IP address or hostname of the Proxmox server"
}
variable "proxmox_ssh_key_path" {
  type        = string
  description = "Path to an SSH key used to connect to the Proxmox server"
}
variable "proxmox_resource_pool" {
  type        = string
  default     = "Kubernetes"
  description = "Resource Pool to create on Proxmox for the cluster"
}


# Talos Image
variable "talos_image_datastore" {
  type        = string
  default     = "local"
  description = "DataStore to use on Proxmox for the Talos image"
}
variable "talos_image_node_name" {
  type        = string
  description = "Proxmox node used for storing the Talos image"
}


# Kubernetes Cluster
variable "talos_version" {
  type        = string
  default     = "v1.12.4"
  description = "Identify here: https://github.com/siderolabs/talos/releases"
}
variable "kubernetes_version" {
  type        = string
  default     = "v1.35.2"
  description = "Identify here: https://github.com/siderolabs/kubelet/pkgs/container/kubelet"
}
variable "kubernetes_cluster_name" {
  type        = string
  default     = "kubernetes"
  description = "Kubernetes cluster name you wish for Talos to use"
}
variable "talos_virtual_ip" {
  type        = string
  description = "Virtual IP address you wish for Talos to use"
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.talos_virtual_ip))
    error_message = "Must be a valid IPv4 address."
  }
}
variable "talos_disable_flannel" {
  type        = bool
  default     = false
  description = "Whether or not the Flannel CNI & Kube Proxy should be disabled for Cilium"
}
variable "controlplane_ip_prefix" {
  # While I use DHCP reservation to assign IP Addresses to each virtual machine, talos must know
  # the IP Address of a node in order to apply configuration and bootstrap it. This prefix is used
  # in combination with the VM count integer to form the dynamic IP Address of each node. As a
  # consequence, only 9 of each ControlPlane and workernode are supported: 101-109
  type        = string
  description = "IP address prefix (less the last digit) of the controlplane nodes"
}
variable "workernode_ip_prefix" {
  # While I use DHCP reservation to assign IP Addresses to each virtual machine, talos must know
  # the IP Address of a node in order to apply configuration and bootstrap it. This prefix is used
  # in combination with the VM count integer to form the dynamic IP Address of each node. As a
  # consequence, only 9 of each ControlPlane and workernode are supported: 151-159
  type        = string
  description = "IP address prefix (less the last digit) of the Worker Nodes"
}


# controlplanes
variable "controlplane_vmid_prefix" {
  # I set my VMIDs according to my IP Addressing.
  # This prefix has the last digit set to the Terraform Count.
  type        = number
  description = "VMID prefix (less the last digit) of the controlplane nodes"
}
variable "controlplane_num" {
  type        = number
  default     = 3
  description = "Quantity of controlplane nodes to provision"
  validation {
    condition     = var.controlplane_num >= 1 && var.controlplane_num <= 9
    error_message = "Control plane count must be between 1 and 9 due to IP/MAC addressing schema"
  }
}
variable "controlplane_hostname_prefix" {
  type        = string
  default     = "k8s-cp"
  description = "Hostname prefix (less the last digit) of the controlplane nodes"
}
variable "controlplane_node_name" {
  type        = string
  description = "Proxmox node used for provisioning the workernodes"
}
variable "controlplane_tags" {
  type        = list(string)
  default     = ["app-kubernetes", "type-controlplane"]
  description = "Tags to apply to the controlplane virtual machines"
}
variable "controlplane_cpu_cores" {
  type        = number
  default     = 4
  description = "Quantity of CPU cores to apply to the controlplane virtual machines"
}
variable "controlplane_memory" {
  type        = number
  default     = 10240
  description = "Quantity of memory (megabytes) to apply to the controlplane virtual machines"
}
variable "controlplane_datastore" {
  type        = string
  default     = "FlashPool"
  description = "Datastore used for the controlplane virtual machines"
}
variable "controlplane_disk_size" {
  # Talos recommends 100Gb
  type        = number
  default     = "50"
  description = "Quantity of disk space (gigabytes) to apply to the controlplane virtual machines"
}
variable "controlplane_network_device" {
  type        = string
  default     = "vmbr0"
  description = "Network device used for the controlplane virtual machines"
}
variable "controlplane_mac_address_prefix" {
  # I use DHCP reservation for assigning static IPs.
  # This prefix has the last digit set to the Terraform Count.
  type        = string
  description = "MAC address (less the last digit) of the controlplane nodes"
}
variable "controlplane_vlan_id" {
  type        = number
  default     = null
  description = "VLAN ID used for the controlplane nodes"
}


# Worker Nodes
variable "workernode_vmid_prefix" {
  # I set my VMIDs according to my IP Addressing.
  # This prefix has the last digit set to the Terraform Count.
  type        = number
  description = "The VMID Prefix (less the last digit) of the workernode nodes"
}
variable "workernode_num" {
  type        = number
  default     = 3
  description = "Quantity of workernode nodes to provision"

  validation {
    condition     = var.workernode_num >= 1 && var.workernode_num <= 9
    error_message = "Worker node count must be between 1 and 9 due to IP/MAC addressing schema"
  }
}
variable "workernode_hostname_prefix" {
  type        = string
  default     = "k8s-node"
  description = "Hostname prefix (less the last digit) of the workernode nodes"
}
variable "workernode_node_name" {
  type        = string
  description = "Proxmox node used for provisioning the workernodes"
}
variable "workernode_tags" {
  type        = list(string)
  default     = ["app-kubernetes", "type-workernode"]
  description = "Tags to apply to the workernode virtual machines"
}
variable "workernode_cpu_cores" {
  type        = number
  default     = 10
  description = "Quantity of CPU cores to apply to the workernode virtual machines"
}
variable "workernode_memory" {
  type        = number
  default     = 51200
  description = "Quantity of memory (megabytes) to apply to the workernode virtual machines"
}
variable "workernode_datastore" {
  type        = string
  default     = "FlashPool"
  description = "Datastore used for the workernode virtual machines"
}
variable "workernode_disk_size" {
  # Talos recommends 100Gb
  type        = number
  default     = "50"
  description = "Quantity of disk space (gigabytes) to apply to the workernode virtual machines"
}
variable "workernode_network_device" {
  type        = string
  default     = "vmbr0"
  description = "Network device used for the workernode virtual machines"
}
variable "workernode_mac_address_prefix" {
  # I use DHCP reservation for assigning static IPs.
  # This prefix has the last digit set to the Terraform Count.
  type        = string
  description = "MAC address (less the last digit) of the workernode nodes"
}
variable "workernode_vlan_id" {
  type        = number
  default     = null
  description = "VLAN ID used for the workernode nodes"
}
