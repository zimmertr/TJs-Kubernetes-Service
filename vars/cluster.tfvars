# =============================================================================
# PROXMOX CONNECTION
# =============================================================================
proxmox_hostname      = "192.168.1.10"       # <--- CHANGE THIS to your Proxmox IP
proxmox_resource_pool = "Kubernetes-Cluster"  
proxmox_ssh_key_path = "/home/master/.ssh/id_rsa" # Use the FULL path, do not use ~/
# =============================================================================
# STORAGE CONFIGURATION 
# =============================================================================
# The tiny ISO file goes to the standard local directory
talos_image_datastore = "local"
talos_image_node_name = "pve"
controlplane_datastore = "local-lvm"
workernode_datastore   = "local-lvm"

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================
# Your Router MUST reserve these IPs for the MAC addresses generated below.
talos_virtual_ip        = "192.168.1.50"      # The Load Balancer IP (VIP)
kubernetes_cluster_name = "talos-home"

# =============================================================================
# CONTROL PLANE NODES (3 Nodes)
# =============================================================================
# RAM: 3GB x 3 = 9GB Total
# CPU: 2 Cores x 3 = 6 vCores
# DISK: 30GB x 3 = 90GB Total
# -----------------------------------------------------------------------------
controlplane_num             = 3
controlplane_hostname_prefix = "k8s-cp"
controlplane_node_name       = "pve"

# IDs will be 801, 802, 803
controlplane_vmid_prefix     = 800

# IPs will be .51, .52, .53 (If prefix is ...1.5)
controlplane_ip_prefix       = "192.168.1.5"

# MACs will be ...11, ...12, ...13
controlplane_mac_address_prefix = "00:00:00:00:00:1"

controlplane_cpu_cores       = 2
controlplane_memory          = 3072
controlplane_disk_size       = "30"
controlplane_network_device  = "vmbr0"

# =============================================================================
# WORKER NODES (3 Nodes)
# =============================================================================
# RAM: 8GB x 3 = 24GB Total
# CPU: 4 Cores x 3 = 12 vCores
# DISK: 50GB x 3 = 150GB Total
# -----------------------------------------------------------------------------
workernode_num               = 3
workernode_hostname_prefix   = "k8s-worker"
workernode_node_name         = "pve"

# IDs will be 901, 902, 903
workernode_vmid_prefix       = 900

# IPs will be .61, .62, .63 (If prefix is ...1.6)
workernode_ip_prefix         = "192.168.1.6"

# MACs will be ...21, ...22, ...23
workernode_mac_address_prefix = "00:00:00:00:00:2"

workernode_cpu_cores         = 4
workernode_memory            = 8192
workernode_disk_size         = "50"
workernode_network_device    = "vmbr0"