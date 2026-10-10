output "map" {
  # Proxmox reports IDs as 0x-prefixed hex, and a mapping wants them bare.
  value = {
    node         = var.node_name
    path         = local.device.id
    id           = "${trimprefix(local.device.vendor, "0x")}:${trimprefix(local.device.device, "0x")}"
    subsystem_id = "${trimprefix(local.device.subsystem_vendor, "0x")}:${trimprefix(local.device.subsystem_device, "0x")}"
    iommu_group  = local.device.iommu_group
  }
  description = "The chosen device as an entry for a proxmox_hardware_mapping_pci map"

  precondition {
    condition     = length(local.matches) == 1
    error_message = "Expected exactly one of the ${var.description}${var.pci_address == null ? "" : " at ${var.pci_address}"} on ${var.node_name}, found ${length(local.matches)}: [${join(", ", [for d in local.matches : d.id])}]. Set ${var.address_input} to choose one."
  }
  precondition {
    # Only judged once a single device is chosen, so it never adds noise to the
    # error above.
    condition     = local.device == null || try(local.device.iommu_group >= 0, false)
    error_message = "${try(local.device.id, "")} is not in an IOMMU group. Enable IOMMU on ${var.node_name}."
  }
}
