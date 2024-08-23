variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "bgp_asn" {
  description = "The BGP ASN number for the Customer Gateway"
  type        = number
}

variable "cgw_eip" {
  description = "The Elastic IP address for the Customer Gateway"
  type        = string
}

variable "client_vpc_cidr" {
  description = "The CIDR block for the client VPC"
  type        = string
}

variable "route_table_id" {
  description = "The ID of the route table for VPN Gateway route propagation"
  type        = string
}

variable "create_vgw" {
  description = "Whether to create a new VPN Gateway"
  type        = bool
  default     = false
}
