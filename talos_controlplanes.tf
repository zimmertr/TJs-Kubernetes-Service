resource "proxmox_virtual_environment_vm" "controlplane" {
  count                     = var.CONTROLPLANE_NUM
  vm_id                     = "${var.CONTROLPLANE_VMID_PREFIX}${count.index + 1}"
  
  pool_id                   = proxmox_virtual_environment_pool.resource_pool.id
  node_name                 = var.CONTROLPLANE_NODE_NAME

  name                      = "${var.CONTROLPLANE_HOSTNAME_PREFIX}-${count.index + 1}"
  description               = "${var.CONTROLPLANE_HOSTNAME_PREFIX}: ${count.index + 1}"
  tags                      = [var.CONTROLPLANE_TAGS]

  agent {
    enabled                 = true
    # If left to default, Terraform will be held for 15 minutes waiting for the agent to start
    # before it is even installed. Prevent this by effectively immediatly timing out.
    timeout                 = "1s"
  }
  operating_system {type    = "l26"  }
  memory {dedicated         = var.CONTROLPLANE_MEMORY}

  cpu {
    cores                   = var.CONTROLPLANE_CPU_CORES
    type                    = "host"
  }

  network_device {
    bridge                  = var.CONTROLPLANE_NETWORK_DEVICE
    mac_address             = "${var.CONTROLPLANE_MAC_ADDRESS_PREFIX}${count.index + 1}"
    vlan_id                 = var.CONTROLPLANE_VLAN_ID
  }

  disk {
    datastore_id            = var.CONTROLPLANE_DATASTORE
    file_id                 = proxmox_virtual_environment_file.talos_image.id
    file_format             = "raw" 
    interface               = "scsi0"
    size                    = var.CONTROLPLANE_DISK_SIZE
  }

  lifecycle {ignore_changes = [tags]}

  # Remove the node from Kubernetes on destroy
  provisioner "local-exec" {
    when                    = destroy
    command                 = "./bin/manage_nodes ${self.name} remove"
  }
}

data "talos_machine_configuration" "controlplane" {
  cluster_name                = var.CLUSTER_NAME
  cluster_endpoint            = "https://${var.VIRTUAL_IP}:6443"

  machine_type                = "controlplane"
  machine_secrets             = talos_machine_secrets.this.machine_secrets
  
  talos_version               = var.TALOS_VERSION
  kubernetes_version          = var.KUBERNETES_VERSION
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on                  = [
    proxmox_virtual_environment_vm.controlplane
  ]

  count                       = var.CONTROLPLANE_NUM
  node                        = local.controlplane_nodes[count.index]
  endpoint                    = local.controlplane_nodes[count.index]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

  config_patches = [
    templatefile("configs/machineconfig_global.yml", {QEMU_GUEST_AGENT_VERSION = var.QEMU_GUEST_AGENT_VERSION}),
    templatefile("configs/machineconfig_controlplane.yml", {VIRTUAL_IP = var.VIRTUAL_IP})
  ]
}
