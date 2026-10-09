output "kubeconfig" {
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
  description = "Admin kubeconfig"
}

output "talosconfig" {
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
  description = "talosctl config for every node"
}

output "nodes" {
  value = merge(
    { for name, n in module.controlplanes.nodes : name => merge(n, { role = "controlplane" }) },
    { for name, n in module.workers.nodes : name => merge(n, { role = "worker" }) },
  )
  description = "Every node's IP, VMID, Proxmox node and role, keyed by hostname. bin/manage_nodes reads it"
}
