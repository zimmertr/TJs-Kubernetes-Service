provider "proxmox" {}
provider "talos" {}

terraform {
  required_version = ">= 1.14.6"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.97.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.10.1"
    }
  }
}
