locals {
  controlplane_nodes = [for i in range(1, var.controlplane_num + 1) : "${var.controlplane_ip_prefix}${i}"]
  worker_nodes       = [for i in range(1, var.workernode_num + 1) : "${var.workernode_ip_prefix}${i}"]
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name = var.kubernetes_cluster_name
  client_configuration    = talos_machine_secrets.this.client_configuration
  endpoints               = [for node in local.controlplane_nodes : node]
}

data "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = local.controlplane_nodes[0]
  node                 = local.controlplane_nodes[0]
}

resource "talos_machine_bootstrap" "this" {
  count = var.controlplane_num
  depends_on = [
    talos_machine_configuration_apply.controlplane
  ]
  endpoint             = local.controlplane_nodes[0]
  node                 = local.controlplane_nodes[0]
  client_configuration = talos_machine_secrets.this.client_configuration
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}
