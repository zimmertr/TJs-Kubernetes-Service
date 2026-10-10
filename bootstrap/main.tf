# Applied once per Proxmox cluster, with root credentials, to create the users
# listed in vars/bootstrap.tfvars, such as the one every TKS cluster runs as.
# Optional: skip it if you already have tokens with the right privileges.
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

resource "proxmox_virtual_environment_role" "this" {
  for_each = var.users

  role_id    = each.value.role
  privileges = each.value.privileges
}

resource "proxmox_virtual_environment_user" "this" {
  for_each = var.users

  user_id = each.key
  comment = each.value.comment
  enabled = true
}

resource "proxmox_acl" "this" {
  for_each = var.users

  path      = "/"
  role_id   = proxmox_virtual_environment_role.this[each.key].role_id
  user_id   = proxmox_virtual_environment_user.this[each.key].user_id
  propagate = true
}

# Without privilege separation the token carries the user's ACL, so there is
# one grant to reason about instead of two.
resource "proxmox_user_token" "this" {
  for_each = var.users

  user_id               = proxmox_virtual_environment_user.this[each.key].user_id
  token_name            = each.value.token_name
  comment               = each.value.comment
  privileges_separation = false
}

