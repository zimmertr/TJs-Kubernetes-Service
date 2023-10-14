# Proxmox #######################
proxmox_hostname                = "earth.sol.milkyway"
proxmox_ssh_key_path            = "~/.ssh/sol.milkyway"
proxmox_resource_pool           = "Kubernetes-Test"


# Talos #########################
talos_image_node_name           = "earth"
talos_virtual_ip                = "192.168.40.220"
talos_disable_flannel           = true


# Kubernetes ####################
kubernetes_cluster_name         = "test"


# Controlplanes #################
controlplane_vmid_prefix        = "4022"              # 40221-40229
controlplane_node_name          = "earth"
controlplane_num                = 1

controlplane_hostname_prefix    = "test-k8s-cp"
controlplane_ip_prefix          = "192.168.40.22"     # 221-229
controlplane_mac_address_prefix = "00:00:00:00:02:2"  # 02:21 - 02:29
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
workernode_vmid_prefix          = "4023"              # 40231-40239
workernode_node_name            = "earth"
workernode_num                  = 1

workernode_hostname_prefix      = "test-k8s-node"
workernode_ip_prefix            = "192.168.40.23"     # 231-239
workernode_mac_address_prefix   = "00:00:00:00:02:3"  # 02:31 - 02:39
workernode_vlan_id              = "40"

workernode_cpu_cores            = "4"
workernode_memory               = "4096"
workernode_disk_size            = "10"

workernode_tags                 = [
  "app-kubernetes",
  "clusterid-test",
  "type-workernode"
]
