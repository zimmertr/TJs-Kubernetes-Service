locals {
  cluster_endpoint = "https://${var.cluster.vip}:6443"
  bootstrap_node   = var.controlplanes.nodes[sort(keys(var.controlplanes.nodes))[0]].ip

  global_patches = [
    templatefile("${path.module}/configs/global.yaml", { talos_installer_image = module.image.installer_image }),
  ]
  # Flannel, kube-proxy and the metrics listeners are configured through
  # control-plane-only documents; workers get them as DaemonSets.
  controlplane_patches = concat(
    local.global_patches,
    [templatefile("${path.module}/configs/controlplane.yaml", { talos_virtual_ip = var.cluster.vip })],
    var.cluster.disable_flannel ? [file("${path.module}/configs/disable_flannel.yaml")] : [],
    var.cluster.expose_metrics ? [file("${path.module}/configs/expose_metrics.yaml")] : [],
  )

  # Pool defaults fill in whatever a node doesn't set itself.
  controlplanes = {
    for name, n in var.controlplanes.nodes : name => {
      ip             = n.ip
      vm_id          = n.vm_id
      cores          = coalesce(n.cores, var.controlplanes.defaults.cores)
      memory_mb      = coalesce(n.memory_mb, var.controlplanes.defaults.memory_mb)
      disk_gb        = coalesce(n.disk_gb, var.controlplanes.defaults.disk_gb)
      tags           = n.tags != null ? n.tags : var.controlplanes.defaults.tags
      config_patches = concat(local.controlplane_patches, [templatefile("${path.module}/configs/hostname.yaml", { hostname = name })])
    }
  }
  workers = {
    for name, n in var.workers.nodes : name => {
      ip             = n.ip
      vm_id          = n.vm_id
      cores          = coalesce(n.cores, var.workers.defaults.cores)
      memory_mb      = coalesce(n.memory_mb, var.workers.defaults.memory_mb)
      disk_gb        = coalesce(n.disk_gb, var.workers.defaults.disk_gb)
      tags           = n.tags != null ? n.tags : var.workers.defaults.tags
      config_patches = concat(local.global_patches, [templatefile("${path.module}/configs/hostname.yaml", { hostname = name })])
    }
  }

  node_cluster = {
    name                 = var.cluster.name
    endpoint             = local.cluster_endpoint
    talos_config_version = var.cluster.talos_config_version
    kubernetes_version   = var.cluster.kubernetes_version
  }
  node_proxmox = {
    node_name    = var.proxmox.node_name
    datastore_id = var.proxmox.datastore_id
    pool_id      = proxmox_virtual_environment_pool.this.pool_id
  }
}

module "image" {
  source = "./modules/talos_image"

  cluster_name  = var.cluster.name
  pool_name     = "general"
  talos_version = var.cluster.talos_version
  node_name     = var.proxmox.node_name
  datastore_id  = var.proxmox.image_datastore_id
}

module "controlplanes" {
  source = "./modules/node"

  machine_type         = "controlplane"
  nodes                = local.controlplanes
  image                = module.image
  proxmox              = local.node_proxmox
  network              = var.network
  cluster              = local.node_cluster
  machine_secrets      = talos_machine_secrets.this.machine_secrets
  client_configuration = talos_machine_secrets.this.client_configuration
  kubeconfig           = ephemeral.talos_cluster_kubeconfig.drain.kubeconfig_raw
}

module "workers" {
  source = "./modules/node"

  machine_type         = "worker"
  nodes                = local.workers
  image                = module.image
  proxmox              = local.node_proxmox
  network              = var.network
  cluster              = local.node_cluster
  machine_secrets      = talos_machine_secrets.this.machine_secrets
  client_configuration = talos_machine_secrets.this.client_configuration
  kubeconfig           = ephemeral.talos_cluster_kubeconfig.drain.kubeconfig_raw
  # Workers wait for the control planes, so creates and upgrades roll control
  # planes first (Kubernetes' version-skew order) and destroys remove workers
  # while the API they drain through still exists. This is not depends_on on
  # the module, which would defer the workers' config reads to apply time
  # whenever a control plane changes and show changes that aren't there.
  wait_for = module.controlplanes.machines
}
