output "map" {
  # Proxmox reports IDs as 0x-prefixed hex, and a mapping wants them bare.
  value = {
    node         = var.node_name
    path         = local.device.id
    id           = "${trimprefix(local.device.vendor, "0x")}:${trimprefix(local.device.device, "0x")}"
    subsystem_id = "${trimprefix(local.device.subsystem_vendor, "0x")}:${trimprefix(local.device.subsystem_device, "0x")}"
    iommu_group  = local.device.iommu_group
  }
  description = "The device as an entry for a proxmox_hardware_mapping_pci map"

  precondition {
    condition     = local.device != null
    error_message = "There is no PCI device at ${var.address} on ${var.node_name}. If the card moved, set its new address."
  }
  precondition {
    # Only judged once the device is found, so it never adds noise to the
    # error above.
    condition     = local.device == null || try(local.device.iommu_group >= 0, false)
    error_message = "${var.address} on ${var.node_name} is not in an IOMMU group. Enable IOMMU on the host."
  }
}

output "label" {
  # Proxmox's PCI ID database can be older than the card and have no name for
  # it (the R9700 had none on 2026-10-10), so the model ID always comes first.
  value       = try(trimspace("${trimprefix(local.device.vendor, "0x")}:${trimprefix(local.device.device, "0x")} ${local.device.device_name == null ? "" : local.device.device_name}"), "")
  description = "The device's model ID and, when Proxmox knows it, its name, so a different device at the address shows up in a plan"
}
