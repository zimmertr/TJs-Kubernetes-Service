mock_provider "proxmox" {}

mock_provider "talos" {
  mock_data "talos_machine_configuration" {
    defaults = {
      machine_configuration = "version: v1alpha1"
    }
  }
}

variables {
  machine_type = "worker"
  nodes = {
    "k8s-node-1" = { ip = "192.168.40.21", vm_id = 4021, cores = 6, memory_mb = 24576, disk_gb = 50, tags = ["type-workernode"], config_patches = [] }
    "k8s-node-2" = { ip = "192.168.40.22", vm_id = 4022, cores = 8, memory_mb = 32768, disk_gb = 100, tags = [], config_patches = [] }
  }
  image = {
    file_id         = "local:import/tks-test-general-v1.14.2.qcow2"
    installer_image = "factory.talos.dev/nocloud-installer/abc123:v1.14.2"
  }
  proxmox = {
    node_name    = "earth"
    datastore_id = "FlashPool"
    pool_id      = "Kubernetes-Test"
  }
  network = {
    cidr        = "192.168.40.0/24"
    gateway     = "192.168.40.1"
    dns_servers = ["192.168.40.1"]
    bridge      = "vmbr0"
    vlan_id     = 40
  }
  cluster = {
    name                 = "test"
    endpoint             = "https://192.168.40.50:6443"
    talos_config_version = "v1.14.2"
    kubernetes_version   = "v1.37.1"
    reset_on_destroy     = true
  }
  machine_secrets = {
    certs = {
      etcd               = { cert = "x", key = "x" }
      k8s                = { cert = "x", key = "x" }
      k8s_aggregator     = { cert = "x", key = "x" }
      k8s_serviceaccount = { key = "x" }
      os                 = { cert = "x", key = "x" }
    }
    cluster    = { id = "x", secret = "x" }
    secrets    = { bootstrap_token = "x", secretbox_encryption_secret = "x" }
    trustdinfo = { token = "x" }
  }
  client_configuration = { ca_certificate = "x", client_certificate = "x", client_key = "x" }
  kubeconfig           = "kubeconfig"
}

run "one_vm_per_node_named_by_hostname" {
  command = plan

  assert {
    condition     = length(proxmox_virtual_environment_vm.this) == 2 && proxmox_virtual_environment_vm.this["k8s-node-2"].name == "k8s-node-2"
    error_message = "Every node gets a VM named after its hostname"
  }
  assert {
    condition     = proxmox_virtual_environment_vm.this["k8s-node-2"].vm_id == 4022 && proxmox_virtual_environment_vm.this["k8s-node-2"].cpu[0].cores == 8
    error_message = "Each VM must use its own node's sizing"
  }
}

run "static_ip_from_cloud_init" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_vm.this["k8s-node-1"].initialization[0].ip_config[0].ipv4[0].address == "192.168.40.21/24"
    error_message = "The node IP must carry the network's prefix length"
  }
  assert {
    condition     = proxmox_virtual_environment_vm.this["k8s-node-1"].initialization[0].ip_config[0].ipv4[0].gateway == "192.168.40.1"
    error_message = "The gateway must come from the network"
  }
}

run "no_balloon_and_trim_reaches_the_datastore" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_vm.this["k8s-node-1"].memory[0].floating == 0
    error_message = "Ballooning must be off"
  }
  assert {
    condition     = proxmox_virtual_environment_vm.this["k8s-node-1"].disk[0].discard == "on"
    error_message = "discard must be on so trim frees thin-provisioned space"
  }
}

run "disks_get_their_own_iothread" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_vm.this["k8s-node-1"].scsi_hardware == "virtio-scsi-single" && proxmox_virtual_environment_vm.this["k8s-node-1"].disk[0].iothread
    error_message = "iothread is ignored unless the SCSI controller is virtio-scsi-single"
  }
}

run "no_pci_devices_by_default" {
  command = plan

  assert {
    condition     = length(proxmox_virtual_environment_vm.this["k8s-node-1"].hostpci) == 0
    error_message = "A pool without PCI devices must not pass any through"
  }
}

run "pci_devices_are_passed_through_as_pcie" {
  command = plan

  variables {
    pci_devices = [{ mapping = "tks-test-gpu" }]
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this["k8s-node-1"].hostpci[0].mapping == "tks-test-gpu" && proxmox_virtual_environment_vm.this["k8s-node-1"].hostpci[0].pcie
    error_message = "Mapped devices must be attached as PCIe"
  }
}

run "upgrades_drain_and_removal_resets" {
  command = plan

  assert {
    condition     = talos_machine.this["k8s-node-1"].image == "factory.talos.dev/nocloud-installer/abc123:v1.14.2" && talos_machine.this["k8s-node-1"].drain_on_upgrade
    error_message = "The installer image drives in-place upgrades, which must drain first"
  }
  assert {
    condition     = talos_machine.this["k8s-node-1"].on_destroy.reset
    error_message = "A removed node must be reset so it leaves the cluster"
  }
}

run "rejects_an_unknown_machine_type" {
  command = plan

  variables {
    machine_type = "gpu"
  }

  expect_failures = [var.machine_type]
}
