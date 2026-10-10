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

locals {
  # TKS's own user is always present and always wins, so a users entry can't
  # drop it or weaken its privileges.
  users = merge(var.users, {
    (var.user_id) = {
      role       = var.role_id
      privileges = local.privileges
      token_name = var.token_name
      comment    = "Terraform user for TJ's Kubernetes Service"
    }
  })
}

resource "proxmox_virtual_environment_role" "this" {
  for_each = local.users

  role_id    = each.value.role
  privileges = each.value.privileges
}

resource "proxmox_virtual_environment_user" "this" {
  for_each = local.users

  user_id = each.key
  comment = each.value.comment
  enabled = true
}

resource "proxmox_acl" "this" {
  for_each = local.users

  path      = "/"
  role_id   = proxmox_virtual_environment_role.this[each.key].role_id
  user_id   = proxmox_virtual_environment_user.this[each.key].user_id
  propagate = true
}

# Without privilege separation the token carries the user's ACL, so there is
# one grant to reason about instead of two.
resource "proxmox_user_token" "this" {
  for_each = local.users

  user_id               = proxmox_virtual_environment_user.this[each.key].user_id
  token_name            = each.value.token_name
  comment               = each.value.comment
  privileges_separation = false
}

# Without these, applying over an older bootstrap creates the new TKS role and
# user while the old ones still exist under their old addresses, and Proxmox
# refuses the duplicate IDs.
moved {
  from = proxmox_virtual_environment_role.tks
  to   = proxmox_virtual_environment_role.this["tks@pve"]
}

moved {
  from = proxmox_virtual_environment_user.tks
  to   = proxmox_virtual_environment_user.this["tks@pve"]
}

moved {
  from = proxmox_acl.tks
  to   = proxmox_acl.this["tks@pve"]
}

moved {
  from = proxmox_user_token.tks
  to   = proxmox_user_token.this["tks@pve"]
}
