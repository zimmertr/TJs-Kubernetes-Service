output "nodes" {
  value       = { for name, node in var.nodes : name => { ip = node.ip, vm_id = node.vm_id } }
  description = "Hostname to IP and VMID for every node in the pool"
}

output "machines" {
  value       = { for name, m in talos_machine.this : name => m.id }
  description = "Hostname to talos_machine ID, for another pool to order itself after"
}
