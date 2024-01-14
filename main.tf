provider "proxmox" {}
provider "talos" {}

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.43.2"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.4.0"
    }
  }
}
