variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
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

variable "vpc_id" {
  description = "Vitural Private Network ID"
  type        = string
}

variable "subnet_id_app_a" {
  description = "Subnet for apse1-az2 (ap-southeast-1a)"
  type        = string
}

variable "subnet_id_app_b" {
  description = "Subnet for apse1-az1 (ap-southeast-1b)"
  type        = string
}