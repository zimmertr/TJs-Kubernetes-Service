# The GPU is found by vendor and class rather than by address, so a hardware
# change or a reinstall that moves it doesn't break the cluster.
data "proxmox_hardware_pci" "gpu" {
  node_name = var.proxmox.node_name
  # The default blacklist is Proxmox's, and it could hide the device.
  pci_class_blacklist = []
  filters = {
    vendor_id = var.pci_vendor_id
    class     = var.pci_class
  }
}

module "device" {
  source = "../pci_device"

  devices       = data.proxmox_hardware_pci.gpu.devices
  pci_address   = var.pci_address
  node_name     = var.proxmox.node_name
  description   = "PCI devices with vendor ${var.pci_vendor_id} and class ${var.pci_class}"
  address_input = "gpu_workers.pci_address"
}

# Attaching by mapping works with an API token; a raw hostpci ID needs root's
# password.
resource "proxmox_hardware_mapping_pci" "gpu" {
  name    = "${var.cluster.name}-gpu"
  comment = "TKS cluster ${var.cluster.name}"

  # Spelled out, because the provider rejects a map entry that is unknown as a
  # whole during validation.
  map = [{
    node         = module.device.map.node
    path         = module.device.map.path
    id           = module.device.map.id
    subsystem_id = module.device.map.subsystem_id
    iommu_group  = module.device.map.iommu_group
  }]
}

locals {
  pci_devices = [{ mapping = proxmox_hardware_mapping_pci.gpu.name, pcie = true }]
}

module "node" {
  source = "../node"

  machine_type         = "worker"
  nodes                = var.nodes
  image                = var.image
  proxmox              = var.proxmox
  network              = var.network
  cluster              = var.cluster
  machine_secrets      = var.machine_secrets
  client_configuration = var.client_configuration
  kubeconfig           = var.kubeconfig
  pci_devices          = local.pci_devices
  wait_for             = var.wait_for
}
