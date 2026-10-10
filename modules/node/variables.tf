variable "machine_type" {
  type        = string
  description = "Talos machine type for every node in this pool"

  validation {
    condition     = contains(["controlplane", "worker"], var.machine_type)
    error_message = "machine_type must be controlplane or worker."
  }
}

variable "nodes" {
  type = map(object({
    ip             = string
    vm_id          = number
    cores          = number
    memory_mb      = number
    disk_gb        = number
    tags           = list(string)
    config_patches = list(string)
    # PCI resource mappings to pass through to this node.
    pci_devices = optional(list(object({
      mapping = string
      pcie    = optional(bool, true)
    })), [])
  }))
  description = "Nodes keyed by hostname, with pool defaults already merged in, each node's rendered Talos patches, and any PCI resource mappings to pass through"
}

variable "image" {
  type = object({
    file_id         = string
    installer_image = string
  })
  description = "The pool's Talos image from modules/talos_image"
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

variable "wait_for" {
  type        = any
  default     = null
  description = "Anything this pool's VMs and machines must be created and upgraded after, and destroyed before"
}
