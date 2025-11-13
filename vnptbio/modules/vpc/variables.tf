variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "eks-vpc"
}

variable "vpc_id" {
  description = "The ID of the VPC (optional if the module creates it)"
  type        = string
  default     = null
}

# variable "vpc_cidr" {
#   description = "CIDR block for the VPC"
#   type        = string
#   default     = "10.233.8.0/24"
# }

# variable "public_subnet_cidr" {
#   description = "CIDR block for the public subnet"
#   type        = string
#   default     = "10.233.8.0/26"
# }

# variable "private_subnet_cidrs" {
#   description = "List of private subnet CIDR blocks"
#   type        = list(string)
#   default     = ["10.233.8.128/26", "10.233.8.192/26"]
# }

variable "cluster_name" {
  description = "EKS cluster name for subnet tagging"
  type        = string
  default     = "biocenter-cluster"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.233.8.0/24"
}

variable "public_subnets_cidrs" {
  description = "List of public subnet CIDRs"
  type        = string
  default     = "10.233.8.0/26"
}

variable "private_subnets_cidrs" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.233.8.128/26", "10.233.8.192/26"]
}

variable "availability_zones" {
  description = "AWS region availability zone(s)"
  type        = string
}
