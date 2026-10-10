# Kept apart from the data source because terraform test can only mock a
# list-nested attribute such as data.proxmox_hardware_pci.devices as empty, so
# the selection is tested here with plain inputs.
locals {
  matches = [for d in var.devices : d if var.pci_address == null || d.id == var.pci_address]
  device  = length(local.matches) == 1 ? local.matches[0] : null
}
