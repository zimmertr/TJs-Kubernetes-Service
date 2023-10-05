resource "proxmox_virtual_environment_vm" "workernode" {
  count = var.workernode_num
  vm_id = "${var.workernode_vmid_prefix}${count.index + 1}"

  pool_id   = proxmox_virtual_environment_pool.proxmox_resource_pool.id
  node_name = var.workernode_node_name

  name        = "${var.workernode_hostname_prefix}-${count.index + 1}"
  description = "${var.workernode_hostname_prefix}: ${count.index + 1}"
  tags        = var.workernode_tags

  cpu {
    cores = var.workernode_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.workernode_memory
  }

  network_device {
    bridge      = var.workernode_network_device
    mac_address = "${var.workernode_mac_address_prefix}${count.index + 1}"
    vlan_id     = var.workernode_vlan_id
  }

  disk {
    datastore_id = var.workernode_datastore
    file_id      = proxmox_virtual_environment_file.talos_image.id
    file_format  = "raw"
    interface    = "scsi0"
    size         = var.workernode_disk_size
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
    command = "./bin/manage_nodes remove ${self.name}"
  }
}

data "talos_machine_configuration" "workernode" {
  cluster_name     = var.kubernetes_cluster_name
  cluster_endpoint = "https://${var.talos_virtual_ip}:6443"

  machine_type    = "worker"
  machine_secrets = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

resource "talos_machine_configuration_apply" "workernode" {
  depends_on = [
    proxmox_virtual_environment_vm.workernode
  ]

  count    = var.workernode_num
  node     = local.worker_nodes[count.index]
  endpoint = local.worker_nodes[count.index]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.workernode.machine_configuration

  config_patches = [
    templatefile("configs/global.yml", {
      qemu_guest_agent_version = var.qemu_guest_agent_version
    })
  ]
}
