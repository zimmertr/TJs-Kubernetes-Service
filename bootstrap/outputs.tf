output "api_tokens" {
  # The provider's value is already the full <id>=<secret> form that
  # PROXMOX_VE_API_TOKEN takes.
  value       = { for user, token in proxmox_user_token.this : user => token.value }
  sensitive   = true
  description = "API token for each user, as <id>=<secret>"
}

# bin/tks reads this with awk, so it needs neither jq nor any other JSON parser.
output "tks" {
  value       = join("\n", [for user, token in proxmox_user_token.this : "${user} ${token.value}"])
  sensitive   = true
  description = "One line per user: the user ID and its API token. bin/tks token reads it"
}
