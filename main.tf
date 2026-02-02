provider "proxmox" {}
provider "talos" {}

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.89.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.9.0"
    }
  }

  required_version = ">= 1.5.0"
}
