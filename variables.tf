variable "proxmox" {
  type = object({
    node_name          = string
    datastore_id       = optional(string, "FlashPool")
    image_datastore_id = optional(string, "local")
    resource_pool      = string
  })
  description = "Where the cluster runs: the Proxmox node, the datastore for VM disks, the datastore for Talos images (it must allow the Import content type), and the resource pool to create"
}

variable "network" {
  type = object({
    cidr        = string
    gateway     = string
    dns_servers = list(string)
    bridge      = optional(string, "vmbr0")
    vlan_id     = optional(number)
  })
  description = "The network every node is attached to. Node IPs are assigned statically from it through cloud-init"

  validation {
    condition     = can(cidrhost(var.network.cidr, 0))
    error_message = "network.cidr must be a valid IPv4 CIDR, e.g. 192.168.40.0/24."
  }
  validation {
    condition     = can(cidrhost("${var.network.gateway}/${split("/", var.network.cidr)[1]}", 0)) && cidrhost("${var.network.gateway}/${split("/", var.network.cidr)[1]}", 0) == cidrhost(var.network.cidr, 0)
    error_message = "network.gateway must be inside network.cidr."
  }
}

variable "cluster" {
  type = object({
    name = string
    vip  = string
    # The installed Talos OS. Renovate bumps it, and changing it upgrades
    # nodes in place.
    talos_version = optional(string, "v1.14.2")
    # The provider's config-generation contract, pinned when the cluster is
    # created. Raising it later changes the generated machine config, not the
    # cluster's secrets.
    talos_config_version = string
    kubernetes_version   = optional(string, "v1.37.1")
    disable_flannel      = optional(bool, false)
    expose_metrics       = optional(bool, false)
    # Nodes leave etcd and wipe themselves when removed. Turn off and apply
    # before destroying a whole cluster: the last control plane can't leave
    # etcd, so its reset fails.
    reset_on_destroy = optional(bool, true)
  })
  description = "Cluster identity, versions and feature switches"

  validation {
    condition     = can(regex("^v\\d+\\.\\d+\\.\\d+$", var.cluster.talos_version)) && can(regex("^v\\d+\\.\\d+\\.\\d+$", var.cluster.talos_config_version)) && can(regex("^v\\d+\\.\\d+\\.\\d+$", var.cluster.kubernetes_version))
    error_message = "Versions must look like v1.2.3."
  }
  validation {
    condition = alltrue([for i, part in split(".", trimprefix(var.cluster.talos_config_version, "v")) :
      tonumber(part) <= tonumber(split(".", trimprefix(var.cluster.talos_version, "v"))[i])
      if i < 2
    ])
    error_message = "cluster.talos_config_version can't be newer than cluster.talos_version."
  }
  validation {
    condition     = can(cidrhost("${var.cluster.vip}/${split("/", var.network.cidr)[1]}", 0)) && cidrhost("${var.cluster.vip}/${split("/", var.network.cidr)[1]}", 0) == cidrhost(var.network.cidr, 0)
    error_message = "cluster.vip must be inside network.cidr."
  }
  validation {
    condition     = !contains([for n in merge(var.controlplanes.nodes, var.workers.nodes) : n.ip], var.cluster.vip)
    error_message = "cluster.vip must not be a node IP."
  }
}

variable "controlplanes" {
  type = object({
    defaults = optional(object({
      cores     = optional(number, 4)
      memory_mb = optional(number, 8192)
      disk_gb   = optional(number, 50)
      tags      = optional(list(string), [])
    }), {})
    nodes = map(object({
      ip        = string
      vm_id     = number
      cores     = optional(number)
      memory_mb = optional(number)
      disk_gb   = optional(number)
      tags      = optional(list(string))
    }))
  })
  description = "Control plane nodes keyed by hostname, with defaults any node can override"

  validation {
    condition     = length(var.controlplanes.nodes) >= 1
    error_message = "At least one control plane is required."
  }
}

variable "workers" {
  type = object({
    defaults = optional(object({
      cores     = optional(number, 4)
      memory_mb = optional(number, 8192)
      disk_gb   = optional(number, 50)
      tags      = optional(list(string), [])
    }), {})
    nodes = optional(map(object({
      ip        = string
      vm_id     = number
      cores     = optional(number)
      memory_mb = optional(number)
      disk_gb   = optional(number)
      tags      = optional(list(string))
    })), {})
  })
  default     = {}
  description = "Worker nodes keyed by hostname, with defaults any node can override"

  # Cross-pool checks live here because every pool is in scope of this rule.
  validation {
    condition = alltrue([
      for n in merge(var.controlplanes.nodes, var.workers.nodes) :
      can(cidrhost("${n.ip}/${split("/", var.network.cidr)[1]}", 0)) && cidrhost("${n.ip}/${split("/", var.network.cidr)[1]}", 0) == cidrhost(var.network.cidr, 0)
    ])
    error_message = "Every node IP must be inside network.cidr."
  }
  validation {
    condition = (
      length(distinct([for n in merge(var.controlplanes.nodes, var.workers.nodes) : n.ip])) ==
      length(merge(var.controlplanes.nodes, var.workers.nodes))
    )
    error_message = "Node IPs must be unique."
  }
  validation {
    condition = (
      length(distinct([for n in merge(var.controlplanes.nodes, var.workers.nodes) : n.vm_id])) ==
      length(merge(var.controlplanes.nodes, var.workers.nodes))
    )
    error_message = "Node VMIDs must be unique."
  }
  validation {
    condition     = length(setintersection(keys(var.controlplanes.nodes), keys(var.workers.nodes))) == 0
    error_message = "A hostname can only belong to one pool."
  }
}
