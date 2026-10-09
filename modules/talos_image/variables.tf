variable "cluster_name" {
  type        = string
  description = "Cluster the image belongs to. Part of the file name, so clusters sharing a datastore never collide"
}

variable "pool_name" {
  type        = string
  description = "Node pool the image belongs to (e.g. general or gpu). Part of the file name, so pools with different extensions never collide"
}

variable "talos_version" {
  type        = string
  description = "Talos version of the image and the installer, e.g. v1.14.2"
}

variable "extensions" {
  type        = list(string)
  default     = ["siderolabs/qemu-guest-agent"]
  description = "Official Talos system extensions baked into the image"
}

variable "node_name" {
  type        = string
  description = "Proxmox node that stores the image"
}

variable "datastore_id" {
  type        = string
  description = "Proxmox datastore that stores the image. It must allow the Import content type"
}
