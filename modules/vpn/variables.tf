variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "bgp_asn" {
  description = "BGP ASN for the Customer Gateway"
  type        = number
}

variable "cgw_eip" {
  description = "Elastic IP for the Customer Gateway"
  type        = string
}

variable "client_vpc_cidr" {
  description = "CIDR block of the client VPC"
  type        = string
}

variable "route_table_id" {
  description = "ID of the route table for VPN route propagation"
  type        = string
}
