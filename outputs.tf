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
    { for name, n in try(module.gpu_workers[0].nodes, {}) : name => merge(n, { role = "worker" }) },
  )
  description = "Every node's IP, VMID, Proxmox node and role, keyed by hostname"
}

# bin/tks reads this with awk, so it needs neither jq nor any other JSON parser.
output "tks" {
  value = join("\n", concat(
    [
      "cluster ${var.cluster.name}",
      "talos_version ${var.cluster.talos_version}",
      "kubernetes_version ${var.cluster.kubernetes_version}",
    ],
    [for name, n in module.controlplanes.nodes : "node ${name} controlplane ${n.ip} ${n.vm_id} ${n.proxmox_node} controlplanes"],
    [for name, n in module.workers.nodes : "node ${name} worker ${n.ip} ${n.vm_id} ${n.proxmox_node} workers"],
    [for name, n in try(module.gpu_workers[0].nodes, {}) : "node ${name} worker ${n.ip} ${n.vm_id} ${n.proxmox_node} gpu"],
  ))
  description = "The cluster's name and versions, and one line per node (name, role, IP, VMID, Proxmox node, pool), control planes first. bin/tks reads it"
}
