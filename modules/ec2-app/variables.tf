variable "instance_count" {
  description = "The number of instances to create"
  type        = number
}

variable "ami_id" {
  description = "The AMI ID to use for the instance"
  type        = string
}

variable "instance_type" {
  description = "The instance type"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the instance in"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
}

variable "iam_instance_profile" {
  description = "The IAM instance profile name to associate with the EC2 instance"
  type        = string
}

variable "user_data" {
  description = "The user data script to use when launching the instance"
  type        = string
  default     = ""
}

variable "security_group_id" {
  description = "The security group ID to assign to the EC2 instance"
  type        = string
}

variable "elasticache_endpoint" {
  description = "The endpoint of the ElastiCache Redis cluster"
  type        = string
}