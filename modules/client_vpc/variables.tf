variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets"
}

variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets"
}

variable "app_vpc_cidr" {
  type        = string
  description = "CIDR block for the app VPC"
}