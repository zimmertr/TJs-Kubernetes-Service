variable "users" {
  type = map(object({
    role       = string
    privileges = list(string)
    token_name = string
    comment    = optional(string)
  }))
  description = "Proxmox users to create, keyed by user ID, such as the one TKS runs as. Each gets its own role, granted on `/`, and an API token"

  validation {
    condition     = length(distinct([for u in values(var.users) : u.role])) == length(var.users)
    error_message = "Every user needs its own role."
  }
}
