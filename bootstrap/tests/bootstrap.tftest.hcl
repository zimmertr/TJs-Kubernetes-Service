mock_provider "proxmox" {
  mock_resource "proxmox_user_token" {
    defaults = {
      id    = "tks@pve!terraform"
      value = "00000000-0000-0000-0000-000000000000"
    }
  }
}

run "token_is_not_privilege_separated" {
  command = plan

  assert {
    condition     = proxmox_user_token.tks.privileges_separation == false
    error_message = "The token must carry the user's ACL"
  }
}

run "acl_grants_the_role_on_the_whole_tree" {
  command = plan

  assert {
    condition     = proxmox_acl.tks.path == "/" && proxmox_acl.tks.propagate
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
    condition     = !contains(proxmox_virtual_environment_role.tks.privileges, "VM.Monitor")
    error_message = "VM.Monitor no longer exists in Proxmox 9"
  }
}

run "can_delete_old_images" {
  command = plan

  assert {
    condition     = contains(proxmox_virtual_environment_role.tks.privileges, "Datastore.Allocate")
    error_message = "Proxmox requires Datastore.Allocate to delete a downloaded image"
  }
}
