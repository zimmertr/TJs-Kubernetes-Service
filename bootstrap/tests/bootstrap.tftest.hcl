mock_provider "proxmox" {
  mock_resource "proxmox_user_token" {
    defaults = {
      id = "tks@pve!terraform"
      # What the provider really returns, checked against a live token on 2026-10-09.
      value = "tks@pve!terraform=00000000-0000-0000-0000-000000000000"
    }
  }
}

run "token_is_not_privilege_separated" {
  command = plan

  assert {
    condition     = proxmox_user_token.this["tks@pve"].privileges_separation == false
    error_message = "The token must carry the user's ACL"
  }
}

run "acl_grants_the_role_on_the_whole_tree" {
  command = plan

  assert {
    condition     = proxmox_acl.this["tks@pve"].path == "/" && proxmox_acl.this["tks@pve"].propagate
    error_message = "TKS needs the role everywhere it creates objects"
  }
}

run "outputs_a_config_env_token" {
  command = apply

  assert {
    condition     = nonsensitive(output.api_token) == "tks@pve!terraform=00000000-0000-0000-0000-000000000000"
    error_message = "api_token must be in PROXMOX_VE_API_TOKEN's <id>=<secret> form"
  }
}

run "no_vm_monitor_privilege" {
  command = plan

  assert {
    condition     = !contains(proxmox_virtual_environment_role.this["tks@pve"].privileges, "VM.Monitor")
    error_message = "VM.Monitor no longer exists in Proxmox 9"
  }
}

run "can_delete_old_images" {
  command = plan

  assert {
    condition     = contains(proxmox_virtual_environment_role.this["tks@pve"].privileges, "Datastore.Allocate")
    error_message = "Proxmox requires Datastore.Allocate to delete a downloaded image"
  }
}

run "no_users_means_only_tks" {
  command = plan

  assert {
    condition     = keys(proxmox_user_token.this) == ["tks@pve"] && length(proxmox_virtual_environment_role.this) == 1
    error_message = "With no users, bootstrap creates only the TKS user"
  }
}

run "users_get_their_own_role_and_token" {
  command = apply

  variables {
    users = {
      "kubernetes-csi@pve" = {
        role       = "CSI"
        privileges = ["VM.Audit", "VM.Config.Disk", "Datastore.Allocate", "Datastore.AllocateSpace", "Datastore.Audit"]
        token_name = "csi"
      }
    }
  }

  override_resource {
    target = proxmox_user_token.this["kubernetes-csi@pve"]
    values = {
      id    = "kubernetes-csi@pve!csi"
      value = "kubernetes-csi@pve!csi=11111111-1111-1111-1111-111111111111"
    }
  }

  assert {
    condition     = proxmox_acl.this["kubernetes-csi@pve"].role_id == "CSI" && proxmox_acl.this["kubernetes-csi@pve"].path == "/"
    error_message = "A user gets its own role on /"
  }

  assert {
    condition     = !contains(proxmox_virtual_environment_role.this["kubernetes-csi@pve"].privileges, "VM.Allocate")
    error_message = "A user gets only the privileges it lists"
  }

  assert {
    condition     = proxmox_user_token.this["kubernetes-csi@pve"].privileges_separation == false
    error_message = "A user's token carries the user's ACL"
  }

  assert {
    condition     = nonsensitive(output.api_tokens) == { "kubernetes-csi@pve" = { id = "kubernetes-csi@pve!csi", secret = "11111111-1111-1111-1111-111111111111" } }
    error_message = "api_tokens holds the ID and secret of each user's token, and not the TKS token"
  }

  assert {
    condition     = nonsensitive(output.api_token) == "tks@pve!terraform=00000000-0000-0000-0000-000000000000"
    error_message = "api_token stays the TKS token"
  }
}

run "users_cannot_replace_tks" {
  command = plan

  variables {
    users = {
      "tks@pve" = {
        role       = "Weaker"
        privileges = ["VM.Audit"]
        token_name = "terraform"
      }
    }
  }

  expect_failures = [var.users]
}

run "users_cannot_share_a_role" {
  command = plan

  variables {
    users = {
      "a@pve" = { role = "Shared", privileges = ["VM.Audit"], token_name = "a" }
      "b@pve" = { role = "Shared", privileges = ["VM.Audit"], token_name = "b" }
    }
  }

  expect_failures = [var.users]
}

run "users_cannot_use_the_tks_role" {
  command = plan

  variables {
    users = {
      "a@pve" = { role = "TKS", privileges = ["VM.Audit"], token_name = "a" }
    }
  }

  expect_failures = [var.users]
}
