# Proxmox #######################
proxmox = {
  node_name     = "earth"
  resource_pool = "Kubernetes-Test"
}


# Network #######################
network = {
  cidr        = "192.168.40.0/24"
  gateway     = "192.168.40.1"
  dns_servers = ["192.168.40.1"]
  vlan_id     = 40
}


# Cluster #######################
cluster = {
  name                    = "test"
  vip                     = "192.168.40.50"
  talos_version           = "v1.14.2"
  talos_config_version    = "v1.14.2"
  kubernetes_version      = "v1.37.1"
  external_cloud_provider = true
}


# Controlplanes #################
controlplanes = {
  defaults = {
    memory_mb = 4096
    disk_gb   = 10
    tags      = ["app-kubernetes", "clusterid-test", "type-controlplane"]
  }
  nodes = {
    "test-k8s-cp-1" = { ip = "192.168.40.51", vm_id = 4051 }
  }
}


# Worker Nodes ##################
workers = {
  defaults = {
    memory_mb = 4096
    disk_gb   = 10
    tags      = ["app-kubernetes", "clusterid-test", "type-workernode"]
  }
  nodes = {
    "test-k8s-node-1" = { ip = "192.168.40.61", vm_id = 4061 }
  }
}
