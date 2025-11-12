variable "role_name" {
  description = "The name of the IAM role"
  type        = string
}

variable "assume_role_policy" {
  description = "The assume role policy document in JSON"
  type        = string
}

variable "policy_name" {
  description = "The name of the custom policy to create"
  type        = string
  default     = null
}

variable "policy_document" {
  description = "The JSON policy document for the custom policy"
  type        = string
  default     = null
}

variable "create_policy" {
  description = "Whether to create a custom IAM policy"
  type        = bool
  default     = false
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
