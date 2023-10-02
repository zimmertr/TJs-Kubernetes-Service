# Proxmox
# I try to use the Proxmox API token where possible, however in the case where you download the
# Talos image, you must use the `remote-exec` provisioner to SSH to the Proxmox server and
# extract the downloaded Talos image.
variable "PROXMOX_IP_ADDRESS" {
  type        = string
  default     = "192.168.20.11"
  description = "IP address or hostname of the Proxmox server"
}
variable "PROXMOX_SSH_KEY_PATH" {
  type        = string
  default     = "~/.ssh/sol.milkyway"
  description = "Path to an SSH key used to connect to the Proxmox server"
}
variable "RESOURCE_POOL" {
  type        = string
  default     = "Kubernetes"
  description = "Resource Pool to create on Proxmox for the cluster"
}


# Talos Image
variable "TALOS_IMAGE_DATASTORE" {
  type        = string
  default     = "local"
  description = "DataStore to use on Proxmox for the Talos image"
}
variable "TALOS_IMAGE_WORKERNODE_NAME" {
  type        = string
  default     = "earth"
  description = "Proxmox node used for storing the Talos image"
}


# Kubernetes Cluster
variable "TALOS_VERSION" {
  type        = string
  default     = "v1.5.3"
  description = "Identify here: https://github.com/siderolabs/talos/releases"
}
variable "KUBERNETES_VERSION" {
  type        = string
  default     = "v1.28.2"
  description = "Identify here: https://github.com/siderolabs/kubelet/pkgs/container/kubelet"
}
variable "QEMU_GUEST_AGENT_VERSION" {
  type        = string
  default     = "8.1.0"
  description = "Identify here: https://github.com/siderolabs/extensions/pkgs/container/qemu-guest-agent"
}
variable "CLUSTER_NAME" {
  type        = string
  default     = "kubernetes"
  description = "Kubernetes cluster name you wish for Talos to use"
}
variable "VIRTUAL_IP" {
  type        = string
  default     = "192.168.40.100"
  description = "Virtual IP address you wish for Talos to use"
}
variable "CONTROLPLANE_IP_PREFIX" {
  # While I use DHCP reservation to assign IP Addresses to each virtual machine, talos must know
  # the IP Address of a node in order to apply configuration and bootstrap it. This prefix is used
  # in combination with the VM count integer to form the dynamic IP Address of each node. As a 
  # consequence, only 9 of each ControlPlane and workernode are supported: 101-109
  type        = string
  default     = "192.168.40.10"
  description = "IP address prefix (less the last digit) of the controlplane nodes"
}
variable "WORKERNODE_IP_PREFIX" {
  # While I use DHCP reservation to assign IP Addresses to each virtual machine, talos must know
  # the IP Address of a node in order to apply configuration and bootstrap it. This prefix is used
  # in combination with the VM count integer to form the dynamic IP Address of each node. As a 
  # consequence, only 9 of each ControlPlane and workernode are supported: 151-159
  type        = string
  default     = "192.168.40.15"
  description = "IP address prefix (less the last digit) of the Worker Nodes"
}


# controlplanes
variable "CONTROLPLANE_VMID_PREFIX" {
  # I set my VMIDs according to my IP Addressing.
  # This prefix has the last digit set to the Terraform Count.
  type        = number
  default     = 4010
  description = "VMID prefix (less the last digit) of the controlplane nodes"
}
variable "CONTROLPLANE_NUM" {
  type        = number
  default     = 3
  description = "Quantity of controlplane nodes to provision"
}
variable "CONTROLPLANE_HOSTNAME_PREFIX" {
  type        = string
  default     = "k8s-cp"
  description = "Hostname prefix (less the last digit) of the controlplane nodes"
}
variable "CONTROLPLANE_WORKERNODE_NAME"{
  type        = string
  default     = "earth"
  description = "Proxmox node used for provisioning the workernodes"
}
variable "CONTROLPLANE_TAGS" {
  type        = string
  default     = "controlplane"
  description = "Tags to apply to the controlplane virtual machines"
}
variable "CONTROLPLANE_CPU_CORES" {
  type        = number
  default     = 4
  description = "Quantity of CPU cores to apply to the controlplane virtual machines"
}
variable "CONTROLPLANE_MEMORY" {
  type        = number
  default     = 10240
  description = "Quantity of memory (megabytes) to apply to the controlplane virtual machines"
}
variable "CONTROLPLANE_DATASTORE" {
  type        = string
  default     = "FlashPool"
  description = "Datastore used for the controlplane virtual machines"
}
variable "CONTROLPLANE_DISK_SIZE" {
  # Talos recommends 100Gb
  type        = string
  default     = "50" 
  description = "Quantity of disk space (gigabytes) to apply to the controlplane virtual machines"
}
variable "CONTROLPLANE_NETWORK_DEVICE" {
  type        = string
  default     = "vmbr0"
  description = "Network device used for the controlplane virtual machines"
}
variable "CONTROLPLANE_MAC_ADDRESS_PREFIX" {
  # I use DHCP reservation for assigning static IPs. 
  # This prefix has the last digit set to the Terraform Count.
  type        = string
  default     = "00:00:00:00:00:0"
  description = "MAC address (less the last digit) of the controlplane nodes"
}
variable "CONTROLPLANE_VLAN_ID" {
  type        = number
  default     = 40
  description = "VLAN ID used for the controlplane nodes"
}


# Worker Nodes
variable "WORKERNODE_VMID_PREFIX" {
  # I set my VMIDs according to my IP Addressing.
  # This prefix has the last digit set to the Terraform Count.
  type        = number
  default     = 4015
  description = "The VMID Prefix (less the last digit) of the workernode nodes"
}
variable "WORKERNODE_NUM" {
  type        = number
  default     = 3
  description = "Quantity of workernode nodes to provision"
}
variable "WORKERNODE_HOSTNAME_PREFIX" {
  type        = string
  default     = "k8s-node"
  description = "Hostname prefix (less the last digit) of the workernode nodes"
}
variable "WORKERNODE_WORKERNODE_NAME"{
  type        = string
  default     = "earth"
  description = "Proxmox node used for provisioning the workernodes"
}
variable "WORKERNODE_TAGS" {
  type        = string
  default     = "workernode"
  description = "Tags to apply to the workernode virtual machines"
}
variable "WORKERNODE_CPU_CORES" {
  type        = number
  default     = 10
  description = "Quantity of CPU cores to apply to the workernode virtual machines"
}
variable "WORKERNODE_MEMORY" {
  type        = number
  default     = 51200
  description = "Quantity of memory (megabytes) to apply to the workernode virtual machines"
}
variable "WORKERNODE_DATASTORE" {
  type        = string
  default     = "FlashPool"
  description = "Datastore used for the workernode virtual machines"
}
variable "WORKERNODE_DISK_SIZE" {
  # Talos recommends 100Gb
  type        = string
  default     = "50"
  description = "Quantity of disk space (gigabytes) to apply to the workernode virtual machines"
}
variable "WORKERNODE_NETWORK_DEVICE" {
  type        = string
  default     = "vmbr0"
  description = "Network device used for the workernode virtual machines"
}
variable "WORKERNODE_MAC_ADDRESS_PREFIX" {
  # I use DHCP reservation for assigning static IPs.
  # This prefix has the last digit set to the Terraform Count.
  type        = string
  default     = "00:00:00:00:00:1"
  description = "MAC address (less the last digit) of the workernode nodes"
}
variable "WORKERNODE_VLAN_ID" {
  type        = number
  default     = 40
  description = "VLAN ID used for the workernode nodes"
}
