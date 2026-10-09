terraform {
  required_version = ">= 1.16"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.116.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12.0"
    }
  }
}
