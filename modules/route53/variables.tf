variable "domain_name" {
  description = "Domain name for the private hosted zone"
  type        = string
}

variable "record_name" {
  description = "Record name for the ALB alias"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the ALB"
  type        = string
}