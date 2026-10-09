locals {
  prefix = split("/", var.network.cidr)[1]
}

resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.nodes

  name      = each.key
  vm_id     = each.value.vm_id
  node_name = var.proxmox.node_name
  pool_id   = var.proxmox.pool_id
  tags      = each.value.tags

  machine = "q35"
  bios    = "ovmf"

  # A removed node is reset and halted by Talos first, and a guest-agent
  # shutdown of a halted VM hangs until the API times out.
  stop_on_destroy = true

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  # floating = 0 removes the balloon device. Passed-through PCI devices need
  # all memory pinned anyway, so every node gets the same fixed allocation.
  memory {
    dedicated = each.value.memory_mb
    floating  = 0
  }

  efi_disk {
    datastore_id      = var.proxmox.datastore_id
    type              = "4m"
    pre_enrolled_keys = false
  }

  disk {
    datastore_id = var.proxmox.datastore_id
    interface    = "scsi0"
    # Read once at creation. A newer image never replaces an existing VM;
    # talos_machine upgrades it in place instead.
    import_from = var.image.file_id
    size        = each.value.disk_gb
    iothread    = true
    ssd         = true
    # Lets Talos's periodic trim hand freed blocks back to a thin datastore.
    discard = "on"
  }

  network_device {
    bridge  = var.network.bridge
    vlan_id = var.network.vlan_id
  }

  initialization {
    datastore_id = var.proxmox.datastore_id
    ip_config {
      ipv4 {
        address = "${each.value.ip}/${local.prefix}"
        gateway = var.network.gateway
      }
    }
    dns {
      servers = var.network.dns_servers
    }
  }

  dynamic "hostpci" {
    for_each = var.pci_devices
    content {
      device  = "hostpci${hostpci.key}"
      mapping = hostpci.value.mapping
      pcie    = hostpci.value.pcie
    }
  }

  agent {
    enabled = true
    # Talos only reports through the agent once it is running, and the
    # default makes Terraform wait 15 minutes for it on every create.
    timeout = "1s"
  }

  operating_system {
    type = "l26"
  }
}

data "talos_machine_configuration" "this" {
  for_each = var.nodes

  cluster_name       = var.cluster.name
  cluster_endpoint   = var.cluster.endpoint
  machine_type       = var.machine_type
  machine_secrets    = var.machine_secrets
  talos_version      = var.cluster.talos_config_version
  kubernetes_version = var.cluster.kubernetes_version
  config_patches     = each.value.config_patches
}

resource "talos_machine" "this" {
  for_each   = var.nodes
  depends_on = [proxmox_virtual_environment_vm.this]

  node                  = each.value.ip
  client_configuration  = var.client_configuration
  machine_configuration = data.talos_machine_configuration.this[each.key].machine_configuration

  # A changed installer image upgrades the node in place, draining it first.
  image            = var.image.installer_image
  drain_on_upgrade = true
  kubeconfig_wo    = var.kubeconfig

  # talos_cluster owns Kubernetes upgrades through upgrade-k8s.
  ignore_kubernetes_upgrade_drift = true

  on_destroy = {
    reset    = var.cluster.reset_on_destroy
    graceful = true
    reboot   = false
  }
}
