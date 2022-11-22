variable "name" {
  type        = string
  description = "IAM role name for IRSA"
}

variable "inline_policy_name" {
  type        = string
  description = "Inline policy name for IRSA"
  default     = "policy"
}

variable "inline_policy" {
  type        = string
  description = "Inline policy (json) for IRSA"
}

variable "permissions_boundary" {
  description = "IAM permissions boundary for IRSA roles"
  type        = string
  default     = ""
}

variable "role_path" {
  description = "IAM role path for IRSA roles"
  type        = string
  default     = "/"
}

variable "cluster_id" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "Region of you eks cluster"
  type        = string
}

variable "oidc_provider" {
  description = "EKS OIDC provider"
  type        = string
  default     = null
}

variable "create_sa" {
  description = "Create Service Accounts ?"
  type        = bool
  default     = false
}

variable "service_accounts" {
  description = "Service accounts map"
  type = map(object({
    name      = string
    namespace = string
    automount = optional(bool, true)
    })
  )
}
