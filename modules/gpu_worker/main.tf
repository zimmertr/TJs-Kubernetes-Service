# One lookup for every GPU node. The address picks the card; the rest of what a
# mapping needs comes from Proxmox.
data "proxmox_hardware_pci" "host" {
  node_name = var.proxmox.node_name
  # Proxmox's default blacklist hides some classes, and a device at a node's
  # address must never be filtered out.
  pci_class_blacklist = []
}

module "device" {
  source   = "../pci_device"
  for_each = var.nodes

  # Rebuilt attribute by attribute, so the module's type never depends on what
  # else the data source returns.
  devices = [for d in data.proxmox_hardware_pci.host.devices : {
    id               = d.id
    vendor           = d.vendor
    device           = d.device
    device_name      = d.device_name
    subsystem_vendor = d.subsystem_vendor
    subsystem_device = d.subsystem_device
    iommu_group      = d.iommu_group
  }]
  address   = each.value.pci_address
  node_name = var.proxmox.node_name
}

# One mapping per node, each holding only that node's card, so no card is ever
# offered to two VMs. Attaching by mapping also works with an API token, where a
# raw hostpci ID needs root's password.
resource "proxmox_hardware_mapping_pci" "gpu" {
  for_each = var.nodes

  name    = "${var.cluster.name}-${each.key}-gpu"
  comment = "TKS cluster ${var.cluster.name}: ${module.device[each.key].name}"

  # Spelled out, because the provider rejects a map entry that is unknown as a
  # whole during validation.
  map = [{
    node         = module.device[each.key].map.node
    path         = module.device[each.key].map.path
    id           = module.device[each.key].map.id
    subsystem_id = module.device[each.key].map.subsystem_id
    iommu_group  = module.device[each.key].map.iommu_group
  }]
}

locals {
  nodes = {
    for name, n in var.nodes : name => {
      ip             = n.ip
      vm_id          = n.vm_id
      cores          = n.cores
      memory_mb      = n.memory_mb
      disk_gb        = n.disk_gb
      tags           = n.tags
      config_patches = n.config_patches
      pci_devices    = [{ mapping = proxmox_hardware_mapping_pci.gpu[name].name, pcie = true }]
    }
  }
}

module "node" {
  source = "../node"

  machine_type         = "worker"
  nodes                = local.nodes
  image                = var.image
  proxmox              = var.proxmox
  network              = var.network
  cluster              = var.cluster
  machine_secrets      = var.machine_secrets
  client_configuration = var.client_configuration
  kubeconfig           = var.kubeconfig
  wait_for             = var.wait_for
}
