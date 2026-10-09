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
