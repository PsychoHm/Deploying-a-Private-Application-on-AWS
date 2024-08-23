variable "app_vpc_cidr" {
  description = "CIDR block for the App VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "app_vpc_name" {
  description = "Name of the App VPC"
  type        = string
  default     = "app-vpc"
}

variable "app_vpc_private_subnet_count" {
  description = "Number of private subnets in the App VPC"
  type        = number
  default     = 4
}

variable "client_vpc_cidr" {
  description = "CIDR block for the Client VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "client_vpc_name" {
  description = "Name of the client VPC"
  type        = string
  default     = "client-vpc"
}

variable "app_vpc_region" {
  description = "The region where the App VPC is located"
  type        = string
  default     = "us-east-1" # or whatever your default App VPC region is
}