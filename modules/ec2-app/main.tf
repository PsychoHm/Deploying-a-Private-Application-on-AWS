terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_instance" "this" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  count           = var.instance_count
  subnet_id       = var.subnet_id
  security_groups = [var.security_group_id]

  tags = var.tags

  iam_instance_profile = var.iam_instance_profile
  user_data            = var.user_data
}