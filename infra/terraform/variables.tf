variable "subscription_id" {
  description = "Azure subscription ID. Not needed for validate/lint; required only for a real plan/apply."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "prefix" {
  description = "Resource name prefix (lowercase letters and digits)."
  type        = string
  default     = "devsecops"
}

variable "suffix" {
  description = "Short unique suffix (ACR and Key Vault names are global)."
  type        = string
  default     = "lab01"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "uaenorth"
}
