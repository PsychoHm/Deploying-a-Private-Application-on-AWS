terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile

  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = var.private_ip
  source_dest_check           = var.disable_source_dest_check ? false : true

  user_data = var.user_data

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_eip" "instance_eip" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.ec2_instance.id

  tags = merge(
    {
      Name = "${var.name}-eip"
    },
    var.tags
  )
}