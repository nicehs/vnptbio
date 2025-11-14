variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "eks_role_arn" {
  description = "IAM role ARN for EKS cluster"
  type        = string
}

variable "eks_node_role_arn" {
  description = "Node role ARN for the EKS node grou"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS cluster and node groups"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Enable private endpoint access"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public endpoint access"
  type        = bool
  default     = false
}

variable "node_group1_instance_type" {
  type        = string
  default     = "t3.medium"
}

variable "node_group2_instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "group1_desired_size" {
  type        = number
  default     = 2
}

variable "group1_min_size" {
  type        = number
  default     = 1
}

variable "group1_max_size" {
  type        = number
  default     = 4
}

variable "group2_desired_size" {
  type        = number
  default     = 2
}

variable "group2_min_size" {
  type        = number
  default     = 1
}

variable "group2_max_size" {
  type        = number
  default     = 4
}

variable "node_role_policy_attachments" {
  description = "List of IAM role policy attachments for node groups"
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "vpc_main_id" {
  description = "The main VPC ID for the EKS cluster"
  type        = string
}

variable "node_AmazonEKSWorkerNodePolicy" {
  description = "Amazon EKS Worker Node Policy"
  type        = string
}

variable "node_AmazonEKS_CNI_Policy" {
  description = "Amazon EKS CNI Policy"
  type        = string
}

variable "node_AmazonEC2ContainerRegistryReadOnly" {
  description = "Amazon EC2 Container Registry ReadOnly Policy"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security group ID for the bastion host"
  type        = string
}