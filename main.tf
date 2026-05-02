provider "proxmox" {}
provider "talos" {}

terraform {
  required_version = ">= 1.14.6"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.100.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.11.0"
    }
  }
}
