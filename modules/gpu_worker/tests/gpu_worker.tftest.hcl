mock_provider "proxmox" {}

# The device lookup is tested in modules/pci_device. Every node gets the same
# stand-in device here, which is enough to check the wiring.
override_module {
  target = module.device
  outputs = {
    map = {
      node         = "earth"
      path         = "0000:05:00.0"
      id           = "1002:7551"
      subsystem_id = "1849:5413"
      iommu_group  = 61
    }
    name = "Navi 48 [Radeon AI PRO R9700]"
  }
}

mock_provider "talos" {
  mock_data "talos_machine_configuration" {
    defaults = {
      machine_configuration = "version: v1alpha1"
    }
  }
}

variables {
  nodes = {
    "k8s-node-gpu-1" = { ip = "192.168.40.31", vm_id = 4031, cores = 16, memory_mb = 196608, disk_gb = 100, tags = [], config_patches = [], pci_address = "0000:05:00.0" }
    "k8s-node-gpu-2" = { ip = "192.168.40.32", vm_id = 4032, cores = 16, memory_mb = 196608, disk_gb = 100, tags = [], config_patches = [], pci_address = "0000:06:00.0" }
  }
  image = {
    file_id         = "local:import/tks-test-gpu-v1.14.2.qcow2"
    installer_image = "factory.talos.dev/nocloud-installer/def456:v1.14.2"
  }
  proxmox = {
    node_name    = "earth"
    datastore_id = "FlashPool"
    pool_id      = "Kubernetes-Test"
  }
  network = {
    cidr    = "192.168.40.0/24"
    gateway = "192.168.40.1"
    bridge  = "vmbr0"
  }
  cluster = {
    name                 = "test"
    endpoint             = "https://192.168.40.50:6443"
    talos_config_version = "v1.14.2"
    kubernetes_version   = "v1.37.1"
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
  kubeconfig           = "x"
}

run "looks_up_every_device_on_the_host" {
  command = plan

  assert {
    condition     = data.proxmox_hardware_pci.host.node_name == "earth" && length(data.proxmox_hardware_pci.host.pci_class_blacklist) == 0
    error_message = "No device may be hidden by Proxmox's default class blacklist"
  }
}

run "each_node_gets_its_own_mapping" {
  command = plan

  assert {
    condition     = length(proxmox_hardware_mapping_pci.gpu) == 2 && proxmox_hardware_mapping_pci.gpu["k8s-node-gpu-1"].name == "test-k8s-node-gpu-1-gpu" && proxmox_hardware_mapping_pci.gpu["k8s-node-gpu-2"].name == "test-k8s-node-gpu-2-gpu"
    error_message = "Each GPU node must get a mapping named after the cluster and the node"
  }
  assert {
    condition     = alltrue([for m in proxmox_hardware_mapping_pci.gpu : length(m.map) == 1])
    error_message = "A mapping must hold exactly one card, so no card is offered to two VMs"
  }
  assert {
    condition     = one(proxmox_hardware_mapping_pci.gpu["k8s-node-gpu-1"].map).path == "0000:05:00.0" && one(proxmox_hardware_mapping_pci.gpu["k8s-node-gpu-1"].map).id == "1002:7551"
    error_message = "The mapping must hold the device the lookup found"
  }
  assert {
    condition     = proxmox_hardware_mapping_pci.gpu["k8s-node-gpu-1"].comment == "TKS cluster test: Navi 48 [Radeon AI PRO R9700]"
    error_message = "The mapping's comment must name the device, so a different one shows up in a plan"
  }
}

run "each_vm_gets_its_own_mapping_as_pcie" {
  command = plan

  assert {
    condition     = local.nodes["k8s-node-gpu-1"].pci_devices == [{ mapping = "test-k8s-node-gpu-1-gpu", pcie = true }] && local.nodes["k8s-node-gpu-2"].pci_devices == [{ mapping = "test-k8s-node-gpu-2-gpu", pcie = true }]
    error_message = "Each VM must get its own card through its own mapping, as a PCIe device"
  }
  assert {
    condition     = module.node.nodes["k8s-node-gpu-1"].vm_id == 4031
    error_message = "GPU nodes must be created through the node module"
  }
}
