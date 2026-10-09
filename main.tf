provider "proxmox" {}
provider "talos" {}

terraform {
  required_version = ">= 1.14.6"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.116.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.6"
    }
  }
}
