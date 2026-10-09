output "api_token" {
  value       = "${proxmox_user_token.tks.id}=${proxmox_user_token.tks.value}"
  sensitive   = true
  description = "PROXMOX_VE_API_TOKEN for vars/config.env"
}

output "privileges" {
  value       = local.privileges
  description = "Privileges granted to the TKS role"
}
