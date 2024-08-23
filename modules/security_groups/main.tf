# main.tf

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us-east-1, aws.us-east-2]
    }
  }
}

resource "aws_security_group" "app_vpc_sg" {
  provider    = aws.us-east-1
  name        = "ApplicationVPCSG"
  description = "Security group for Application VPC"
  vpc_id      = var.app_vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.app_vpc_cidr]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.client_vpc_cidr]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.client_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ApplicationVPCSG"
  }
}

resource "aws_security_group" "alb_sg" {
  provider    = aws.us-east-1
  name        = "ALBSG"
  description = "Security group for ALB"
  vpc_id      = var.app_vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.client_vpc_cidr]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.app_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALBSG"
  }
}

resource "aws_security_group" "resolver_endpoint_sg" {
  provider    = aws.us-east-1
  name        = "Resolver_EndpointSG"
  description = "Security group for Resolver Endpoint"
  vpc_id      = var.app_vpc_id

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.client_vpc_cidr]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.client_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Resolver_EndpointSG"
  }
}

resource "aws_security_group" "cgw_sg" {
  provider    = aws.us-east-2 # Changed to us-east-2
  name        = "CGW_SG"
  description = "Security group for the CGW"
  vpc_id      = var.client_vpc_id # Changed to client_vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.client_vpc_cidr, var.app_vpc_cidr]
    description = "Allow all traffic from Client VPC and App VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CGW_SG"
  }
}


resource "aws_security_group" "client_sg" {
  provider    = aws.us-east-2
  name        = "Client_SG"
  description = "Security group for Client instance"
  vpc_id      = var.client_vpc_id

  # Allow all inbound traffic from Client VPC CIDR
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.client_vpc_cidr]
  }

  # Allow all inbound traffic from App VPC CIDR
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.app_vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Client_SG"
  }
}

resource "aws_security_group" "elasticache_sg" {
  name        = "elasticache-sg"
  description = "Security group for ElastiCache"
  vpc_id      = var.app_vpc_id

  ingress {
    description = "Allow Redis traffic from App VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.app_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "elasticache-sg"
  }
}