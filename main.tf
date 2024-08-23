# 1. Terraform and provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}

# Configure AWS provider for us-east-1 region
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# Configure AWS provider for us-east-2 region
provider "aws" {
  alias  = "us-east-2"
  region = "us-east-2"
}

# 2. IAM and S3 setup

# Create IAM roles and policies
module "iam" {
  source = "./modules/iam"
  providers = {
    aws = aws.us-east-1
  }
}

# Create S3 bucket for ALB logs
module "s3" {
  source      = "./modules/s3"
  bucket_name = "myappalb.logs77399957" # Unique bucket name
  providers = {
    aws = aws.us-east-1
  }
}

# 3. VPC and networking setup

# Create the application VPC in us-east-1
module "app_vpc" {
  source               = "./modules/app_vpc"
  vpc_cidr             = var.app_vpc_cidr
  vpc_name             = var.app_vpc_name
  private_subnet_count = var.app_vpc_private_subnet_count
  public_subnet_count  = 1
  client_vpc_cidr      = var.client_vpc_cidr
  providers = {
    aws = aws.us-east-1
  }
}

# Create the client VPC in us-east-2
module "client_vpc" {
  source               = "./modules/client_vpc"
  vpc_cidr             = var.client_vpc_cidr
  vpc_name             = var.client_vpc_name
  private_subnet_count = 1
  public_subnet_count  = 1
  app_vpc_cidr         = var.app_vpc_cidr
  providers = {
    aws = aws.us-east-2
  }
}

# 4. Security groups

# Create security groups for both VPCs
module "security_groups" {
  source          = "./modules/security_groups"
  app_vpc_id      = module.app_vpc.vpc_id
  client_vpc_id   = module.client_vpc.vpc_id
  app_vpc_cidr    = var.app_vpc_cidr
  client_vpc_cidr = var.client_vpc_cidr

  providers = {
    aws.us-east-1 = aws.us-east-1
    aws.us-east-2 = aws.us-east-2
  }
}

# ElastiCache setup
module "elasticache" {
  source            = "./modules/elasticache"
  subnet_ids        = module.app_vpc.elasticache_subnet_ids
  security_group_id = module.security_groups.elasticache_sg_id
  node_type         = "cache.t3.micro"
  providers = {
    aws = aws.us-east-1
  }
}

# 5. EC2 instances for the application

# Create first EC2 instance for the application
module "ec2_app1" {
  source               = "./modules/ec2-app"
  instance_count       = 1
  ami_id               = "ami-0aa7d40eeae50c9a9" # Use a valid AMI ID for the region
  instance_type        = "t2.micro"
  subnet_id            = module.app_vpc.private_subnet_ids[0]
  tags                 = { Name = "AppInstance1" }
  iam_instance_profile = module.iam.instance_profile_name
  user_data = templatefile("${path.module}/user_data_scripts/app_user_data.sh", {
    elasticache_endpoint = module.elasticache.redis_endpoint
  })
  security_group_id    = module.security_groups.app_vpc_sg_id
  elasticache_endpoint = module.elasticache.redis_endpoint
  providers = {
    aws = aws.us-east-1
  }
}

# Create second EC2 instance for the application
module "ec2_app2" {
  source               = "./modules/ec2-app"
  instance_count       = 1
  ami_id               = "ami-0aa7d40eeae50c9a9" # Use a valid AMI ID for the region
  instance_type        = "t2.micro"
  subnet_id            = module.app_vpc.private_subnet_ids[1]
  tags                 = { Name = "AppInstance2" }
  iam_instance_profile = module.iam.instance_profile_name
  user_data = templatefile("${path.module}/user_data_scripts/app_user_data.sh", {
    elasticache_endpoint = module.elasticache.redis_endpoint
  })
  security_group_id    = module.security_groups.app_vpc_sg_id
  elasticache_endpoint = module.elasticache.redis_endpoint
  providers = {
    aws = aws.us-east-1
  }
}

# 6. Application Load Balancer

# Create Application Load Balancer
module "alb" {
  source             = "./modules/alb"
  vpc_id             = module.app_vpc.vpc_id
  private_subnet_ids = [module.app_vpc.private_subnet_ids[0], module.app_vpc.private_subnet_ids[1]]
  alb_sg_id          = module.security_groups.alb_sg_id
  access_logs_bucket = module.s3.bucket_name
  providers = {
    aws = aws.us-east-1
  }
}

# Attach first EC2 instance to ALB target group
resource "aws_lb_target_group_attachment" "app1_tg_attachment" {
  provider         = aws.us-east-1
  target_group_arn = module.alb.app_tg_arn
  target_id        = module.ec2_app1.instance_ids[0]
  port             = 5000
}

# Attach second EC2 instance to ALB target group
resource "aws_lb_target_group_attachment" "app2_tg_attachment" {
  provider         = aws.us-east-1
  target_group_arn = module.alb.app_tg_arn
  target_id        = module.ec2_app2.instance_ids[0]
  port             = 5000
}

# EIP for Customer Gateway (CGW)

# Create Elastic IP for CGW
resource "aws_eip" "cgw_eip" {
  provider = aws.us-east-2
  vpc      = true
  tags     = { Name = "CGW-EIP" }
}

# Create EC2 instance for Customer Gateway
module "ec2_cgw" {
  source                      = "./modules/ec2-client"
  ami_id                      = "ami-05c3dc660cb6907f0" # Use a valid AMI ID for the region
  instance_type               = "t2.micro"
  subnet_id                   = module.client_vpc.public_subnet_id
  security_group_id           = module.security_groups.cgw_sg_id
  iam_instance_profile        = module.iam.instance_profile_name
  name                        = "CGW"
  tags                        = { Name = "CGW" }
  associate_public_ip_address = true
  create_eip                  = false
  region                      = "us-east-2"
  disable_source_dest_check   = true
  private_ip                  = cidrhost(module.client_vpc.public_subnet_cidr, 4)
  providers = {
    aws = aws.us-east-2
  }
}

# Create SSM documents and associations for CGW
module "ssm_cgw" {
  source            = "./modules/ssm"
  vpn_connection_id = module.vpn.vpn_connection_id
  app_vpc_region    = "us-east-1"
  r53_resolver_ip1  = module.resolver.resolver_ips[0]
  r53_resolver_ip2  = module.resolver.resolver_ips[1]
  client_vpc_cidr   = module.client_vpc.vpc_cidr
  app_vpc_cidr      = var.app_vpc_cidr
  vpc_router        = cidrhost(module.client_vpc.vpc_cidr, 2)
  private_ip        = cidrhost(module.client_vpc.public_subnet_cidr, 4)
  domain            = "myapp.internal"
  instance_id       = module.ec2_cgw.instance_id
  providers = {
    aws = aws.us-east-2
  }
}

# Associate Elastic IP with CGW instance
resource "aws_eip_association" "cgw_eip_assoc" {
  provider      = aws.us-east-2
  instance_id   = module.ec2_cgw.instance_id
  allocation_id = aws_eip.cgw_eip.id
}

# Add route to App VPC through CGW
resource "aws_route" "to_app_vpc" {
  provider               = aws.us-east-2
  route_table_id         = module.client_vpc.private_route_table_id
  destination_cidr_block = var.app_vpc_cidr
  network_interface_id   = module.ec2_cgw.network_interface_id

  lifecycle {
    create_before_destroy = true
  }
}

# DHCP Options Set for Client VPC with both AmazonProvidedDNS and CGW private IP

# Create DHCP options set
resource "aws_vpc_dhcp_options" "client_dhcp_options" {
  provider            = aws.us-east-2
  domain_name         = "myapp.internal"
  domain_name_servers = [module.ec2_cgw.private_ip, "AmazonProvidedDNS"]
  tags = {
    Name = "${var.client_vpc_name}-dhcp-options"
  }
}

# Associate DHCP options set with Client VPC
resource "aws_vpc_dhcp_options_association" "client_vpc_dhcp_assoc" {
  provider        = aws.us-east-2
  vpc_id          = module.client_vpc.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.client_dhcp_options.id
}

# Create EC2 instance for client in Client VPC
module "ec2_client" {
  source               = "./modules/ec2-client"
  ami_id               = "ami-05c3dc660cb6907f0" # Use a valid AMI ID for the region
  instance_type        = "t2.micro"
  subnet_id            = module.client_vpc.private_subnet_id
  security_group_id    = module.security_groups.client_sg_id
  iam_instance_profile = module.iam.instance_profile_name
  user_data = templatefile("${path.module}/user_data_scripts/client_user_data.sh", {
    cgw_private_ip = module.ec2_cgw.private_ip
  })
  name   = "Client"
  tags   = { Name = "Client" }
  region = "us-east-2"
  providers = {
    aws = aws.us-east-2
  }
  depends_on = [aws_vpc_dhcp_options_association.client_vpc_dhcp_assoc]
}

# 8. VPN setup

# Create VPN connection between App VPC and Client VPC
module "vpn" {
  source          = "./modules/vpn"
  vpc_id          = module.app_vpc.vpc_id
  vpc_name        = var.app_vpc_name
  bgp_asn         = 65000
  cgw_eip         = aws_eip.cgw_eip.public_ip
  client_vpc_cidr = var.client_vpc_cidr
  route_table_id  = module.app_vpc.private_route_table_id
  providers = {
    aws = aws.us-east-1
  }
}

# 9. Route53 and DNS resolver setup

# Create Route53 private hosted zone and record
module "route53" {
  source       = "./modules/route53"
  domain_name  = "myapp.internal"
  record_name  = "access.myapp.internal"
  vpc_id       = module.app_vpc.vpc_id
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
  providers = {
    aws = aws.us-east-1
  }
}

# Create Route53 Resolver endpoints
module "resolver" {
  source         = "./modules/resolver"
  resolver_sg_id = module.security_groups.resolver_endpoint_sg_id
  subnet_id_1    = module.app_vpc.private_subnet_ids[2]
  subnet_id_2    = module.app_vpc.private_subnet_ids[3]
  providers = {
    aws = aws.us-east-1
  }
}