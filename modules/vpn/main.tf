terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}

# Check for existing VPN Gateway with the specific name
data "aws_vpn_gateway" "existing" {
  count = var.create_vgw ? 0 : 1
  filter {
    name   = "tag:Name"
    values = ["app-vpc-vgw"]
  }
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

# Create VPN Gateway if one doesn't exist and create_vgw is true
resource "aws_vpn_gateway" "vgw" {
  count  = var.create_vgw ? 1 : 0
  vpc_id = var.vpc_id

  tags = {
    Name = "app-vpc-vgw"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Use existing VGW if available, otherwise use the newly created one
locals {
  vgw_id = var.create_vgw ? aws_vpn_gateway.vgw[0].id : try(data.aws_vpn_gateway.existing[0].id, aws_vpn_gateway.vgw[0].id)
}

# Create Customer Gateway
resource "aws_customer_gateway" "cgw" {
  bgp_asn    = var.bgp_asn
  ip_address = var.cgw_eip
  type       = "ipsec.1"

  tags = {
    Name = "${var.vpc_name}-cgw"
  }
}

# Create VPN Connection
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = local.vgw_id
  customer_gateway_id = aws_customer_gateway.cgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "${var.vpc_name}-vpn-connection"
  }
}

# Create VPN Connection Route
resource "aws_vpn_connection_route" "main" {
  destination_cidr_block = var.client_vpc_cidr
  vpn_connection_id      = aws_vpn_connection.main.id
}

# Enable route propagation
resource "aws_vpn_gateway_route_propagation" "main" {
  vpn_gateway_id = local.vgw_id
  route_table_id = var.route_table_id
}
