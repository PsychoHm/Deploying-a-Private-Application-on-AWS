terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}

resource "aws_route53_zone" "private" {
  name = var.domain_name
  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "alb_alias" {
  zone_id = aws_route53_zone.private.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }
}