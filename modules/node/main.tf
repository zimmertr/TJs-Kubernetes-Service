locals {
  prefix = split("/", var.network.cidr)[1]
}

resource "proxmox_virtual_environment_vm" "this" {
  for_each   = var.nodes
  depends_on = [var.wait_for]

  name      = each.key
  vm_id     = each.value.vm_id
  node_name = var.proxmox.node_name
  pool_id   = var.proxmox.pool_id
  tags      = each.value.tags

  machine = "q35"
  bios    = "ovmf"
  # iothread on the disk only takes effect with one controller per disk.
  scsi_hardware = "virtio-scsi-single"

  # A node bin/tks already reset is halted, and a guest-agent shutdown
  # of a halted VM hangs until the API times out.
  stop_on_destroy = true

  # Proxmox would restart the VM the moment its hardware changes, and Terraform
  # moves straight on to the next one, so every control plane could restart
  # at once. bin/tks reboot applies the change one node at a time.
  reboot_after_update = false

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

  # SecureBoot needs the 4m variables store. No keys are pre-enrolled, so UEFI
  # boots in setup mode and the Talos image enrolls its own on first boot.
  efi_disk {
    datastore_id      = var.proxmox.datastore_id
    type              = "4m"
    pre_enrolled_keys = false
  }

  disk {
    datastore_id = var.proxmox.datastore_id
    interface    = "scsi0"
    import_from  = var.image.file_id
    size         = each.value.disk_gb
    iothread     = true
    ssd          = true
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
    # Without a dns block, Proxmox hands the VM its host's resolvers from /etc/resolv.conf.
    dynamic "dns" {
      for_each = var.network.dns_servers == null ? [] : [var.network.dns_servers]
      content {
        servers = dns.value
      }
    }
  }

  dynamic "hostpci" {
    for_each = each.value.pci_devices
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

  # The image is only read at creation, and talos_machine upgrades the OS in
  # place. Without this, every Talos upgrade plans a no-op change to every VM.
  lifecycle {
    ignore_changes = [disk[0].import_from]
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
  depends_on = [proxmox_virtual_environment_vm.this, var.wait_for]

  node                  = each.value.ip
  client_configuration  = var.client_configuration
  machine_configuration = data.talos_machine_configuration.this[each.key].machine_configuration

  # A changed installer image upgrades the node in place, draining it first.
  image            = var.image.installer_image
  drain_on_upgrade = true
  kubeconfig_wo    = var.kubeconfig

  # talos_cluster owns Kubernetes upgrades through upgrade-k8s.
  ignore_kubernetes_upgrade_drift = true

  # Destroying a node only deletes its VM. A reset here would run on every
  # node during a full destroy: the last control plane can't leave etcd, and
  # the last worker can't drain past PodDisruptionBudgets. bin/tks remove does
  # that cleanup for a single node instead. Set explicitly, because leaving it
  # out would keep an earlier reset = true from state.
  on_destroy = {
    reset = false
  }
}
