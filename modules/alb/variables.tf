variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security Group ID for ALB"
  type        = string
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
}