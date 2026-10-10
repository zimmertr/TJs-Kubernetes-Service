output "api_token" {
  # The provider's value is already the full <id>=<secret> form.
  value       = proxmox_user_token.this[var.user_id].value
  sensitive   = true
  description = "PROXMOX_VE_API_TOKEN for vars/config.env"
}

output "api_tokens" {
  # Most tools other than TKS want the ID and the secret separately.
  value = {
    for user in keys(var.users) : user => {
      id     = proxmox_user_token.this[user].id
      secret = trimprefix(proxmox_user_token.this[user].value, "${proxmox_user_token.this[user].id}=")
    }
  }
  sensitive   = true
  description = "Token ID and secret for each of users"
}

output "privileges" {
  value       = local.privileges
  description = "Privileges granted to the TKS role"
}
