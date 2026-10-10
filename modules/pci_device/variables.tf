variable "devices" {
  type = list(object({
    id               = string
    vendor           = string
    device           = string
    device_name      = string
    subsystem_vendor = string
    subsystem_device = string
    iommu_group      = number
  }))
  description = "The host's PCI devices, as data.proxmox_hardware_pci returns them"
}

variable "address" {
  type        = string
  description = "PCI address of the device to use, e.g. 0000:05:00.0"
}

variable "node_name" {
  type        = string
  description = "Proxmox node the devices are on"
}
