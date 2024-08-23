terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}

resource "aws_ssm_document" "cgw_setup" {
  name            = "CGW-Setup"
  document_type   = "Command"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm-document/cgw_setup.yaml", {
    vpnConnectionId = var.vpn_connection_id
    appVpcRegion    = var.app_vpc_region
    r53ResolverIp1  = var.r53_resolver_ip1
    r53ResolverIp2  = var.r53_resolver_ip2
    clientVpcCidr   = var.client_vpc_cidr
    appVpcCidr      = var.app_vpc_cidr
    vpcRouter       = var.vpc_router
    domain          = var.domain
  })
}

resource "aws_ssm_association" "cgw_setup" {
  name = aws_ssm_document.cgw_setup.name

  targets {
    key    = "InstanceIds"
    values = [var.instance_id]
  }

  parameters = {
    vpnConnectionId = var.vpn_connection_id
    appVpcRegion    = var.app_vpc_region
    r53ResolverIp1  = var.r53_resolver_ip1
    r53ResolverIp2  = var.r53_resolver_ip2
    clientVpcCidr   = var.client_vpc_cidr
    appVpcCidr      = var.app_vpc_cidr
    vpcRouter       = var.vpc_router
    domain          = var.domain
  }
}