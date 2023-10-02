resource "proxmox_virtual_environment_pool" "resource_pool" {
  comment = "Resources pertaining to Kubernetes"
  pool_id = var.RESOURCE_POOL
}
