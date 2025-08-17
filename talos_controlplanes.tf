resource "proxmox_virtual_environment_vm" "controlplane" {
  count = var.controlplane_num
  vm_id = "${var.controlplane_vmid_prefix}${count.index + 1}"

  pool_id   = proxmox_virtual_environment_pool.proxmox_resource_pool.id
  node_name = var.controlplane_node_name

  name        = "${var.controlplane_hostname_prefix}-${count.index + 1}"
  description = "${var.controlplane_hostname_prefix}: ${count.index + 1}"
  tags        = var.controlplane_tags

  cpu {
    cores = var.controlplane_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.controlplane_memory
  }

  network_device {
    bridge      = var.controlplane_network_device
    mac_address = "${var.controlplane_mac_address_prefix}${count.index + 1}"
    vlan_id     = var.controlplane_vlan_id
  }

  disk {
    datastore_id = var.controlplane_datastore
    file_id      = proxmox_virtual_environment_file.talos_image.id
    file_format  = "raw"
    interface    = "scsi0"
    size         = var.controlplane_disk_size
  }

  agent {
    enabled = true
    # If left to default, Terraform will be held for 15 minutes waiting for the agent to start
    # before it is even installed. Prevent this by effectively immediatly timing out.
    timeout = "1s"
  }

  operating_system {
    type = "l26"
  }

  # Remove the node from Kubernetes on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/bin/manage_nodes remove ${self.name}"
  }
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.kubernetes_cluster_name
  cluster_endpoint = "https://${var.talos_virtual_ip}:6443"

  machine_type    = "controlplane"
  machine_secrets = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [
    proxmox_virtual_environment_vm.controlplane
  ]

  count    = var.controlplane_num
  node     = local.controlplane_nodes[count.index]
  endpoint = local.controlplane_nodes[count.index]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

  config_patches = [
    file("${path.module}/configs/global.yml"),
    templatefile("${path.module}/configs/controlplane.yml", {talos_virtual_ip = var.talos_virtual_ip}),
    var.talos_disable_flannel ? templatefile("${path.module}/configs/disable_flannel.yml", {}) : null
  ]
}
