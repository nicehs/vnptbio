variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_role_arn" {
  description = "IAM role ARN used by the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "EKS version"
  type        = string
  default     = "1.31"
}

variable "subnet_ids" {
  description = "Subnets for EKS cluster networking"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Enable private endpoint access"
  type        = bool
  default     = false
}

variable "endpoint_public_access" {
  description = "Enable public endpoint access"
  type        = bool
  default     = true
}

variable "service_ipv4_cidr" {
  description = "Service IPv4 CIDR block"
  type        = string
  default     = null
}

variable "enabled_cluster_log_types" {
  description = "List of enabled cluster log types"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "node_groups" {
  description = "Map of EKS node groups"
  type = map(object({
    node_role_arn  = string
    subnet_ids     = list(string)
    desired_size   = number
    max_size       = number
    min_size       = number
    instance_types = list(string)
    ami_type       = string
    disk_size      = number
    capacity_type  = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
