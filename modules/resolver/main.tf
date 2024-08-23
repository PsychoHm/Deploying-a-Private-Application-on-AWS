terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}

resource "aws_route53_resolver_endpoint" "inbound" {
  name               = "InboundResolver"
  direction          = "INBOUND"
  security_group_ids = [var.resolver_sg_id]

  ip_address {
    subnet_id = var.subnet_id_1
  }

  ip_address {
    subnet_id = var.subnet_id_2
  }
}