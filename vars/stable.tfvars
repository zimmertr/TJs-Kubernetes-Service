# Proxmox #######################
proxmox = {
  node_name     = "earth"
  resource_pool = "Kubernetes-Stable"
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
  name                 = "stable"
  vip                  = "192.168.40.10"
  talos_version        = "v1.14.2"
  talos_config_version = "v1.14.2"
  kubernetes_version   = "v1.37.1"
  expose_metrics       = true
}


# Controlplanes #################
controlplanes = {
  defaults = {
    cores     = 4
    memory_mb = 8192
    tags      = ["app-kubernetes", "clusterid-stable", "type-controlplane"]
  }
  nodes = {
    "k8s-cp-1" = { ip = "192.168.40.11", vm_id = 4011 }
    "k8s-cp-2" = { ip = "192.168.40.12", vm_id = 4012 }
    "k8s-cp-3" = { ip = "192.168.40.13", vm_id = 4013 }
  }
}


# Worker Nodes ##################
workers = {
  defaults = {
    cores     = 6
    memory_mb = 24576
    tags      = ["app-kubernetes", "clusterid-stable", "type-workernode"]
  }
  nodes = {
    "k8s-node-1" = { ip = "192.168.40.21", vm_id = 4021 }
    "k8s-node-2" = { ip = "192.168.40.22", vm_id = 4022 }
    "k8s-node-3" = { ip = "192.168.40.23", vm_id = 4023 }
  }
}
