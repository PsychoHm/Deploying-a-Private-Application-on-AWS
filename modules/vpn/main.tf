terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}

resource "aws_vpn_gateway" "vgw" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.vpc_name}-vgw"
  }
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
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.cgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "${var.vpc_name}-vpn-connection"
  }
}

resource "aws_vpn_connection_route" "main" {
  destination_cidr_block = var.client_vpc_cidr
  vpn_connection_id      = aws_vpn_connection.main.id
}

resource "aws_vpn_gateway_route_propagation" "main" {
  vpn_gateway_id = aws_vpn_gateway.vgw.id
  route_table_id = var.route_table_id
}