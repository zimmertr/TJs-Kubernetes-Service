provider "proxmox" {}
provider "talos" {}

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.82.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.8.1"
    }
  }
}
