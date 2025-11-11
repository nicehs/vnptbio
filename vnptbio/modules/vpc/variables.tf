variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.233.8.0/24"
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.233.8.0/28"
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.233.8.16/28", "10.233.8.32/28"]
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
