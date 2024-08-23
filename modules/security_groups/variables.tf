# variables.tf

variable "app_vpc_id" {
  description = "The ID of the Application VPC"
  type        = string
}

variable "client_vpc_id" {
  description = "The ID of the Client VPC"
  type        = string
}

variable "app_vpc_cidr" {
  description = "The CIDR block of the Application VPC"
  type        = string
}

variable "client_vpc_cidr" {
  description = "The CIDR block of the Client VPC"
  type        = string
}