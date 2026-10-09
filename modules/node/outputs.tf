output "nodes" {
  value       = { for name, node in var.nodes : name => { ip = node.ip, vm_id = node.vm_id } }
  description = "Hostname to IP and VMID for every node in the pool"
}
