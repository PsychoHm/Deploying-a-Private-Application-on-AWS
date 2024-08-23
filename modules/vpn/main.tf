terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}

# Check for existing VPN Gateway
data "aws_vpn_gateway" "existing" {
  count = var.vpc_id != "" ? 1 : 0
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

# Create VPN Gateway
resource "aws_vpn_gateway" "vgw" {
  count  = length(data.aws_vpn_gateway.existing) == 0 ? 1 : 0
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.vpc_name}-vgw"
  }
}

# Use existing VGW if available, otherwise use the newly created one
locals {
  vgw_id = length(data.aws_vpn_gateway.existing) > 0 ? data.aws_vpn_gateway.existing[0].id : try(aws_vpn_gateway.vgw[0].id, "")
}

resource "aws_customer_gateway" "cgw" {
  bgp_asn    = var.bgp_asn
  ip_address = var.cgw_eip
  type       = "ipsec.1"

  tags = {
    Name = "${var.vpc_name}-cgw"
  }
}

resource "aws_vpn_connection" "main" {
  count               = local.vgw_id != "" ? 1 : 0
  vpn_gateway_id      = local.vgw_id
  customer_gateway_id = aws_customer_gateway.cgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "${var.vpc_name}-vpn-connection"
  }
}

resource "aws_vpn_connection_route" "main" {
  count                  = local.vgw_id != "" ? 1 : 0
  destination_cidr_block = var.client_vpc_cidr
  vpn_connection_id      = aws_vpn_connection.main[0].id
}

resource "aws_vpn_gateway_route_propagation" "main" {
  count          = local.vgw_id != "" ? 1 : 0
  vpn_gateway_id = local.vgw_id
  route_table_id = var.route_table_id
}
