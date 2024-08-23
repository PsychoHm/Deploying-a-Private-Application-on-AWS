variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the ElastiCache cluster"
}

variable "security_group_id" {
  type        = string
  description = "ID of the security group for the ElastiCache cluster"
}

variable "node_type" {
  type        = string
  description = "The compute and memory capacity of the nodes"
  default     = "cache.t3.micro"
}