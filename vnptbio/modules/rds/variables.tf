variable "db_password" {
  description = "The password for the PostgreSQL RDS instance"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS cluster and node groups"
  type        = list(string)
}

variable "vpc_id" {
  description = "The main VPC ID for the EKS cluster"
  type        = string
}