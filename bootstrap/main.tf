# Applied once per Proxmox cluster, with root credentials, to create the user
# every TKS cluster runs as. Optional: skip it if you already have a token
# with these privileges.
provider "proxmox" {}

terraform {
  required_version = ">= 1.16"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.116.0"
    }
  }
}

locals {
  # The subset of bpg's recommended Terraform role that TKS exercises.
  # docs/SECURITY_GUIDE.md explains why each one is needed.
  privileges = [
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.AllocateTemplate",
    "Datastore.Audit",
    "Mapping.Audit",
    "Mapping.Modify",
    "Mapping.Use",
    "Pool.Allocate",
    "Pool.Audit",
    "SDN.Audit",
    "SDN.Use",
    "Sys.Audit",
    "Sys.Modify",
    "VM.Allocate",
    "VM.Audit",
    "VM.Config.CDROM",
    "VM.Config.CPU",
    "VM.Config.Cloudinit",
    "VM.Config.Disk",
    "VM.Config.HWType",
    "VM.Config.Memory",
    "VM.Config.Network",
    "VM.Config.Options",
    "VM.GuestAgent.Audit",
    "VM.PowerMgmt",
  ]
}

resource "proxmox_virtual_environment_role" "tks" {
  role_id    = var.role_id
  privileges = local.privileges
}

resource "proxmox_virtual_environment_user" "tks" {
  user_id = var.user_id
  comment = "Terraform user for TJ's Kubernetes Service"
  enabled = true
}

resource "proxmox_acl" "tks" {
  path      = "/"
  role_id   = proxmox_virtual_environment_role.tks.role_id
  user_id   = proxmox_virtual_environment_user.tks.user_id
  propagate = true
}

# Without privilege separation the token carries the user's ACL, so there is
# one grant to reason about instead of two.
resource "proxmox_user_token" "tks" {
  user_id               = proxmox_virtual_environment_user.tks.user_id
  token_name            = var.token_name
  comment               = "TKS clusters"
  privileges_separation = false
}
