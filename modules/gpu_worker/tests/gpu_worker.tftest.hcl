mock_provider "proxmox" {}

# The device lookup is tested in modules/pci_device.
override_module {
  target = module.device
  outputs = {
    map = {
      node         = "earth"
      path         = "0000:05:00.0"
      id           = "1002:7551"
      subsystem_id = "1002:0603"
      iommu_group  = 61
    }
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
    "k8s-node-gpu-1" = { ip = "192.168.40.31", vm_id = 4031, cores = 16, memory_mb = 196608, disk_gb = 100, tags = [], config_patches = [] }
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

run "finds_the_gpu_by_vendor_and_class" {
  command = plan

  assert {
    condition     = data.proxmox_hardware_pci.gpu.filters.vendor_id == "0x1002" && data.proxmox_hardware_pci.gpu.filters.class == "0x03"
    error_message = "The GPU must be looked up by AMD's vendor ID and the display controller class"
  }
  assert {
    condition     = length(data.proxmox_hardware_pci.gpu.pci_class_blacklist) == 0
    error_message = "Proxmox's default class blacklist must not hide the device"
  }
}

run "mapping_is_named_after_the_cluster_and_holds_the_device" {
  command = plan

  assert {
    condition     = proxmox_hardware_mapping_pci.gpu.name == "test-gpu"
    error_message = "The mapping must be named after the cluster"
  }
  assert {
    condition     = one(proxmox_hardware_mapping_pci.gpu.map).path == "0000:05:00.0" && one(proxmox_hardware_mapping_pci.gpu.map).id == "1002:7551" && one(proxmox_hardware_mapping_pci.gpu.map).iommu_group == 61
    error_message = "The mapping must hold the device the lookup chose"
  }
}

run "vm_gets_the_gpu_as_pcie" {
  command = plan

  assert {
    condition     = local.pci_devices == [{ mapping = "test-gpu", pcie = true }]
    error_message = "The VM must get the GPU through the mapping, as a PCIe device"
  }
  assert {
    condition     = module.node.nodes["k8s-node-gpu-1"].vm_id == 4031
    error_message = "The GPU node must be created through the node module"
  }
}
