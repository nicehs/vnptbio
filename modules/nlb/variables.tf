variable "eks_nodes_sg_id" {
  description = "Security group ID for EKS nodes"
  type        = string
}

variable "sg_name" {
  description = "Security group name for NLB"
  type        = string
  default     = "nlb-sg"
}

variable "subnet_mapping" {
  description = "Map of subnets and private IPs (key = zone, value = { subnet_id, private_ip })"
  type = map(object({
    subnet_id  = string
    private_ip = string
  }))
}

variable "nodeport" {
  description = "NodePort used by NLB target groups"
  type        = number
  default     = 31730
}

# variable "instance_ids" {
#   description = "List of EKS node instance IDs"
#   type        = list(string)
# }

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_main_id" {
  description = "The main VPC ID for the EKS cluster"
  type        = string
}