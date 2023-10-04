locals {
  controlplane_nodes = [for i in range(1, var.CONTROLPLANE_NUM + 1) : "${var.CONTROLPLANE_IP_PREFIX}${i}"]
  worker_nodes       = [for i in range(1, var.WORKERNODE_NUM + 1) : "${var.WORKERNODE_IP_PREFIX}${i}"]
}

resource "talos_machine_secrets" "this" {
  talos_version = var.TALOS_VERSION
}

data "talos_client_configuration" "this" {
  cluster_name         = var.CLUSTER_NAME
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for node in local.controlplane_nodes : node]
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
  count = var.CONTROLPLANE_NUM
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
