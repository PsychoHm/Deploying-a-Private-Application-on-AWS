variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID where the EC2 instance will be launched"
  type        = string
}

variable "security_group_id" {
  description = "The security group ID for the EC2 instance"
  type        = string
}

variable "iam_instance_profile" {
  description = "The IAM instance profile for the EC2 instance"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the EC2 instance"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "The user data script for the EC2 instance"
  type        = string
  default     = ""
}

variable "name" {
  description = "The name tag for the EC2 instance"
  type        = string
}

variable "tags" {
  description = "Additional tags for the EC2 instance"
  type        = map(string)
  default     = {}
}

variable "create_eip" {
  description = "Whether to create an Elastic IP for the EC2 instance"
  type        = bool
  default     = false
}

variable "disable_source_dest_check" {
  description = "Whether to disable source/destination check on the EC2 instance"
  type        = bool
  default     = false
}

variable "region" {
  description = "The AWS region where the EC2 instance will be created"
  type        = string
}

variable "cgw_private_ip" {
  description = "Private IP of the CGW instance"
  type        = string
  default     = ""
}

variable "r53_resolver_ip1" {
  description = "IP address of the first Route 53 Resolver endpoint"
  type        = string
  default     = ""
}

variable "r53_resolver_ip2" {
  description = "IP address of the second Route 53 Resolver endpoint"
  type        = string
  default     = ""
}

variable "private_ip" {
  description = "The private IP to assign to the instance (optional)"
  default     = null
}