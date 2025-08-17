# Proxmox #######################
proxmox_hostname                = "earth.sol.milkyway"
proxmox_ssh_key_path            = "~/.ssh/sol.milkyway"
proxmox_resource_pool           = "Kubernetes-Test"


# Talos #########################
talos_image_node_name           = "earth"
talos_virtual_ip                = "192.168.40.50"
talos_disable_flannel           = true


# Kubernetes ####################
kubernetes_cluster_name         = "test"


# Controlplanes #################
controlplane_vmid_prefix        = "405"               # 4051-4059
controlplane_node_name          = "earth"
controlplane_num                = 1

controlplane_hostname_prefix    = "test-k8s-cp"
controlplane_ip_prefix          = "192.168.40.5"      # 51-59
controlplane_mac_address_prefix = "00:00:00:00:00:5"  # 00:51 - 00:59
controlplane_vlan_id            = "40"

controlplane_cpu_cores          = "4"
controlplane_memory             = "4096"
controlplane_disk_size          = "10"

controlplane_tags               = [
  "app-kubernetes",
  "clusterid-test",
  "type-controlplane"
]


# Worker Nodes ##################
workernode_vmid_prefix          = "406"               # 4061-4069
workernode_node_name            = "earth"
workernode_num                  = 1

workernode_hostname_prefix      = "test-k8s-node"
workernode_ip_prefix            = "192.168.40.6"      # 62-69
workernode_mac_address_prefix   = "00:00:00:00:00:6"  # 00:61 - 00:69
workernode_vlan_id              = "40"

workernode_cpu_cores            = "4"
workernode_memory               = "4096"
workernode_disk_size            = "10"

workernode_tags                 = [
  "app-kubernetes",
  "clusterid-test",
  "type-workernode"
]
