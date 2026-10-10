output "nodes" {
  value       = module.node.nodes
  description = "Hostname to IP, VMID and Proxmox node for every GPU node"
}

output "machines" {
  value       = module.node.machines
  description = "Hostname to talos_machine ID for every GPU node"
}

output "mapping" {
  value       = proxmox_hardware_mapping_pci.gpu.name
  description = "Name of the PCI resource mapping the GPU is attached through"
}
