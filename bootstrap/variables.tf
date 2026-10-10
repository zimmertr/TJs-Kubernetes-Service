variable "user_id" {
  type        = string
  default     = "tks@pve"
  description = "Proxmox user TKS runs as"
}

variable "role_id" {
  type        = string
  default     = "TKS"
  description = "Role holding the privileges TKS needs"
}

variable "token_name" {
  type        = string
  default     = "terraform"
  description = "Name of the API token"
}

variable "users" {
  type = map(object({
    role       = string
    privileges = list(string)
    token_name = string
    comment    = optional(string)
  }))
  default     = {}
  description = "More Proxmox users to create, keyed by user ID, for things running in the cluster such as the Proxmox CSI plugin. Each gets its own role, granted on `/`, and an API token"

  validation {
    condition     = !contains(keys(var.users), var.user_id)
    error_message = "The TKS user is created already. Leave it out of users."
  }

  validation {
    condition     = length(distinct([for u in values(var.users) : u.role])) == length(var.users) && !contains([for u in values(var.users) : u.role], var.role_id)
    error_message = "Every user needs its own role, and none can use the TKS role."
  }
}
