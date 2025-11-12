variable "name" {
  description = "The name of the Network Load Balancer"
  type        = string
}

variable "internal" {
  description = "If true, NLB will be internal"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "List of subnet IDs for the NLB"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the target group"
  type        = string
}

variable "target_group_name" {
  description = "Name of the target group"
  type        = string
}

variable "target_type" {
  description = "Type of target group (instance, ip, lambda)"
  type        = string
  default     = "instance"
}

variable "target_port" {
  description = "Port for the target group"
  type        = number
}

variable "target_protocol" {
  description = "Protocol for the target group"
  type        = string
  default     = "TCP"
}

variable "listener_port" {
  description = "Port for the listener"
  type        = number
}

variable "listener_protocol" {
  description = "Protocol for the listener"
  type        = string
  default     = "TCP"
}

variable "health_check_enabled" {
  description = "Whether health check is enabled"
  type        = bool
  default     = true
}

variable "health_check_protocol" {
  description = "Protocol for health check"
  type        = string
  default     = "TCP"
}

variable "health_check_path" {
  description = "Path for HTTP health check (if used)"
  type        = string
  default     = null
}

variable "health_check_interval" {
  description = "Interval between health checks"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout for health check"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of successes before marking healthy"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "Number of failures before marking unhealthy"
  type        = number
  default     = 3
}

variable "target_attachments" {
  description = "Map of target attachments (id and port)"
  type = map(object({
    target_id = string
    port      = number
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
