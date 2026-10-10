variable "nodes" {
  type = map(object({
    ip             = string
    vm_id          = number
    cores          = number
    memory_mb      = number
    disk_gb        = number
    tags           = list(string)
    config_patches = list(string)
  }))
  description = "GPU nodes keyed by hostname, with pool defaults already merged in, and each node's rendered Talos patches"
}

variable "image" {
  type = object({
    file_id         = string
    installer_image = string
  })
  description = "The GPU pool's Talos image from modules/talos_image"
}

variable "proxmox" {
  type = object({
    node_name    = string
    datastore_id = string
    pool_id      = string
  })
  description = "Proxmox node, VM disk datastore and resource pool"
}

variable "network" {
  type = object({
    cidr        = string
    gateway     = string
    dns_servers = optional(list(string))
    bridge      = string
    vlan_id     = optional(number)
  })
  description = "Network every node is attached to"
}

variable "cluster" {
  type = object({
    name                 = string
    endpoint             = string
    talos_config_version = string
    kubernetes_version   = string
  })
  description = "Cluster identity and versions"
}

variable "machine_secrets" {
  type        = any
  sensitive   = true
  description = "talos_machine_secrets.machine_secrets"
}

variable "client_configuration" {
  type        = any
  sensitive   = true
  description = "talos_machine_secrets.client_configuration"
}

variable "kubeconfig" {
  type        = string
  sensitive   = true
  ephemeral   = true
  description = "Admin kubeconfig used to drain nodes before an upgrade. Ephemeral, so it never reaches state"
}

variable "pci_vendor_id" {
  type        = string
  default     = "0x1002"
  description = "PCI vendor ID of the GPU, matched by prefix. The default is AMD"
}

variable "pci_class" {
  type        = string
  default     = "0x03"
  description = "PCI class of the GPU, matched by prefix. The default matches every display controller"
}

variable "pci_address" {
  type        = string
  default     = null
  description = "PCI address of the GPU, e.g. 0000:05:00.0. Only needed when more than one device matches the vendor and class"
}

variable "wait_for" {
  type        = any
  default     = null
  description = "Anything the GPU nodes must be created and upgraded after, and destroyed before"
}
