output "nodes" {
  value       = module.node.nodes
  description = "Hostname to IP, VMID and Proxmox node for every GPU node"
}

output "machines" {
  value       = module.node.machines
  description = "Hostname to talos_machine ID for every GPU node"
}

output "mappings" {
  value       = { for name, m in proxmox_hardware_mapping_pci.gpu : name => m.name }
  description = "Hostname to the name of the PCI resource mapping its GPU is attached through"
}
