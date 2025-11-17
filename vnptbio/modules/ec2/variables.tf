variable "name" {
  description = "Name of the bastion host"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where bastion will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for bastion host (should be public subnet)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the bastion host"
  type        = string
}

variable "instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDRs allowed to SSH into bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_key_pair" {
  description = "Whether to create a new key pair"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Existing key pair name or name for the new key pair"
  type        = string
}

variable "public_key" {
  description = "Public key material (required if create_key_pair = true)"
  type        = string
  default     = null
}

variable "create_eip" {
  description = "Whether to attach an Elastic IP to the bastion host"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "bastion_ssm_role_name" {
  description = "IAM role name for the bastion SSM access"
  type        = string
}

variable "bastion_ssm_profile_name" {
  description = "IAM instance profile name for the bastion SSM access"
  type        = string
}

variable "aws_eks_cluster_biocenter_cluster" {
  description = "EKS cluster object for dependency"
  type        = any
}