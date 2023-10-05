resource "proxmox_virtual_environment_pool" "proxmox_resource_pool" {
  comment = "Resources pertaining to Kubernetes"
  pool_id = var.proxmox_resource_pool
}
