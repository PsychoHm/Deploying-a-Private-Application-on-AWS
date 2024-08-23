variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 1
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
}

variable "client_vpc_cidr" {
  description = "CIDR block of the Client VPC"
  type        = string
}