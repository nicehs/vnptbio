variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name used as prefix for resources"
  type        = string
  default     = "vnpt-bio"
}

variable "create_iam_oidc_provider" {
  description = "Whether to create IAM OIDC provider for EKS"
  type        = bool
  default     = false
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "Vitural Private Network ID"
  type        = string
  default     = "vpc-0077f7d4a639c2578"
}

variable "subnet_id_app_a" {
  description = "Subnet for apse1-az2 (ap-southeast-1a)"
  type        = string
  default     = "subnet-0c8a0d9a16bdbd921"
}

variable "subnet_id_app_b" {
  description = "Subnet for apse1-az1 (ap-southeast-1b)"
  type        = string
  default     = "subnet-02e479709559acb30"
}

# variable "db_password" {
#   description = "Database password for RDS Postgres"
#   type        = string
#   default     = "Vnpt#ekyc2024"
#   sensitive   = true
# }