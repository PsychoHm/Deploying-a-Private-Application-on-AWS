variable "resolver_sg_id" {
  description = "Security Group ID for Resolver"
  type        = string
}

variable "subnet_id_1" {
  description = "First Subnet ID for the resolver endpoint"
  type        = string
}

variable "subnet_id_2" {
  description = "Second Subnet ID for the resolver endpoint"
  type        = string
}