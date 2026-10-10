output "api_tokens" {
  # The provider's value is already the full <id>=<secret> form that
  # PROXMOX_VE_API_TOKEN takes.
  value       = { for user, token in proxmox_user_token.this : user => token.value }
  sensitive   = true
  description = "API token for each user, as <id>=<secret>"
}
