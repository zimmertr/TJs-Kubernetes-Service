resource "proxmox_virtual_environment_pool" "this" {
  pool_id = var.proxmox.resource_pool
  comment = "TKS cluster ${var.cluster.name}"
}

resource "talos_machine_secrets" "this" {
  talos_version = var.cluster.talos_config_version

  # Lowering talos_version replaces the secrets, which regenerates every
  # certificate and strands the running nodes. The secrets only need it at
  # creation, so later changes to talos_config_version are ignored here.
  lifecycle {
    ignore_changes = [talos_version]
  }
}

# Generated offline from the secrets, so nodes can be drained during an
# upgrade without the kubeconfig ever being written to state.
ephemeral "talos_cluster_kubeconfig" "drain" {
  machine_secrets = talos_machine_secrets.this.machine_secrets
  cluster_name    = var.cluster.name
  endpoint        = local.cluster_endpoint
}

# Bootstraps etcd on the first control plane, and runs Talos's health-gated
# upgrade-k8s whenever kubernetes_version changes.
resource "talos_cluster" "this" {
  depends_on = [module.controlplanes]

  node                 = local.bootstrap_node
  control_plane_nodes  = [for n in local.controlplanes : n.ip]
  client_configuration = talos_machine_secrets.this.client_configuration
  kubernetes_version   = var.cluster.kubernetes_version
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_cluster.this]

  node                 = local.bootstrap_node
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for n in local.controlplanes : n.ip]
  nodes                = [for n in merge(local.controlplanes, local.workers) : n.ip]
}
