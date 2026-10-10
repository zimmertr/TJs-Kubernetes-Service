# make test runs these with vars/bootstrap.tfvars, so the users and privileges
# checked here are the ones that get applied.
mock_provider "proxmox" {
  mock_resource "proxmox_user_token" {
    defaults = {
      id = "tks@pve!terraform"
      # What the provider really returns, checked against a live token on 2026-10-09.
      value = "tks@pve!terraform=00000000-0000-0000-0000-000000000000"
    }
  }
}

run "tokens_are_not_privilege_separated" {
  command = plan

  assert {
    condition     = alltrue([for t in proxmox_user_token.this : t.privileges_separation == false])
    error_message = "Each token must carry its user's ACL"
  }
}

run "each_user_gets_its_own_role_on_the_whole_tree" {
  command = plan

  assert {
    condition     = alltrue([for k, a in proxmox_acl.this : a.path == "/" && a.propagate && a.role_id == var.users[k].role])
    error_message = "Each user needs its role everywhere its tool creates or reads objects"
  }
}

run "outputs_config_env_tokens" {
  command = apply

  assert {
    condition     = nonsensitive(output.api_tokens)["tks@pve"] == "tks@pve!terraform=00000000-0000-0000-0000-000000000000"
    error_message = "api_tokens must be in PROXMOX_VE_API_TOKEN's <id>=<secret> form"
  }
  assert {
    condition     = contains(split("\n", nonsensitive(output.tks)), "tks@pve tks@pve!terraform=00000000-0000-0000-0000-000000000000")
    error_message = "bin/tks token reads each user's token as a USER TOKEN line"
  }
}

run "no_vm_monitor_privilege" {
  command = plan

  assert {
    condition     = alltrue([for r in proxmox_virtual_environment_role.this : !contains(r.privileges, "VM.Monitor")])
    error_message = "VM.Monitor no longer exists in Proxmox 9"
  }
}

run "tks_can_delete_old_images" {
  command = plan

  assert {
    condition     = contains(proxmox_virtual_environment_role.this["tks@pve"].privileges, "Datastore.Allocate")
    error_message = "Proxmox requires Datastore.Allocate to delete a downloaded image"
  }
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

run "no_users_means_nothing" {
  command = plan

  variables {
    users = {}
  }

  assert {
    condition     = length(proxmox_user_token.this) == 0 && length(proxmox_virtual_environment_role.this) == 0
    error_message = "bootstrap creates only the users it is given"
  }
}
