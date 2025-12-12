variable "vpc_id" {
  description = "ID of the VPC where secondary CIDR will be added"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster for subnet tagging"
  type        = string
}

variable "vpc_endpoint_id" {
  description = "VPC Endpoint ID for private connectivity (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}