variable "devices" {
  type = list(object({
    id               = string
    vendor           = string
    device           = string
    subsystem_vendor = string
    subsystem_device = string
    iommu_group      = number
  }))
  description = "Candidate devices, as data.proxmox_hardware_pci returns them"
}

variable "pci_address" {
  type        = string
  default     = null
  description = "PCI address that chooses one device when several are candidates"
}

variable "node_name" {
  type        = string
  description = "Proxmox node the devices are on"
}

variable "description" {
  type        = string
  description = "What the candidates are, for error messages, e.g. \"PCI devices with vendor 0x1002 and class 0x03\""
}

variable "address_input" {
  type        = string
  default     = "pci_address"
  description = "Name of the input a user sets to choose a device, for error messages"
}
