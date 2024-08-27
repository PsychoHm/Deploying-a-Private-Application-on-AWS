# 1. Terraform and provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}

# AWS provider for us-east-1 region
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# AWS provider for us-east-2 region
provider "aws" {
  alias  = "us-east-2"
  region = "us-east-2"
}

# 2. VPC and networking setup
# Application VPC in us-east-1
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

# Client VPC in us-east-2
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

# 3. Security groups
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

# 4. VPN and VGW setup
# Elastic IP for Customer Gateway
resource "aws_eip" "cgw_eip" {
  provider = aws.us-east-2
  vpc      = true
  tags     = { Name = "CGW-EIP" }
}

# VPN connection setup
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

# 5. ElastiCache setup
module "elasticache" {
  source            = "./modules/elasticache"
  subnet_ids        = module.app_vpc.elasticache_subnet_ids
  security_group_id = module.security_groups.elasticache_sg_id
  node_type         = "cache.t3.micro"
  providers = {
    aws = aws.us-east-1
  }
}

# 6. IAM and S3 setup
module "iam" {
  source = "./modules/iam"
  providers = {
    aws = aws.us-east-1
  }
}

# Get latest AMI for us-east-1
data "external" "ami_us_east_1" {
  program = ["bash", "${path.module}/scripts/get_latest_ami.sh", "us-east-1", "amzn2-ami-kernel-5.10-hvm-2.0*"]
}

# Get latest AMI for us-east-2
data "external" "ami_us_east_2" {
  program = ["bash", "${path.module}/scripts/get_latest_ami.sh", "us-east-2", "amzn2-ami-kernel-5.10-hvm-2.0*"]
}

# Generate unique S3 bucket name
data "external" "s3_bucket_name" {
  program = ["bash", "${path.module}/scripts/suggest_bucket_name.sh", "us-east-1", "myappalb-logs"]
}

# S3 bucket for ALB logs
module "s3" {
  source      = "./modules/s3"
  bucket_name = data.external.s3_bucket_name.result.bucket_name
  providers = {
    aws = aws.us-east-1
  }
}

# 7. EC2 instances for the application
# Application instance 1
module "ec2_app1" {
  source               = "./modules/ec2-app"
  instance_count       = 1
  ami_id               = data.external.ami_us_east_1.result.ami_id
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
  depends_on = [module.elasticache, module.vpn]
}

# Application instance 2
module "ec2_app2" {
  source               = "./modules/ec2-app"
  instance_count       = 1
  ami_id               = data.external.ami_us_east_1.result.ami_id
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
  depends_on = [module.elasticache, module.vpn]
}

# 8. Application Load Balancer
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

# Attach app instance 1 to ALB target group
resource "aws_lb_target_group_attachment" "app1_tg_attachment" {
  provider         = aws.us-east-1
  target_group_arn = module.alb.app_tg_arn
  target_id        = module.ec2_app1.instance_ids[0]
  port             = 5000
}

# Attach app instance 2 to ALB target group
resource "aws_lb_target_group_attachment" "app2_tg_attachment" {
  provider         = aws.us-east-1
  target_group_arn = module.alb.app_tg_arn
  target_id        = module.ec2_app2.instance_ids[0]
  port             = 5000
}

# 9. CGW setup
module "ec2_cgw" {
  source                      = "./modules/ec2-client"
  ami_id                      = data.external.ami_us_east_2.result.ami_id
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

# SSM configuration for CGW
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

# Route from client VPC to app VPC through CGW
resource "aws_route" "to_app_vpc" {
  provider               = aws.us-east-2
  route_table_id         = module.client_vpc.private_route_table_id
  destination_cidr_block = var.app_vpc_cidr
  network_interface_id   = module.ec2_cgw.network_interface_id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [module.ec2_cgw]
}

# 10. DNS and Route53 setup
# DHCP options for client VPC
resource "aws_vpc_dhcp_options" "client_dhcp_options" {
  provider            = aws.us-east-2
  domain_name         = "myapp.internal"
  domain_name_servers = [module.ec2_cgw.private_ip, "AmazonProvidedDNS"]
  tags = {
    Name = "${var.client_vpc_name}-dhcp-options"
  }
}

# Associate DHCP options with client VPC
resource "aws_vpc_dhcp_options_association" "client_vpc_dhcp_assoc" {
  provider        = aws.us-east-2
  vpc_id          = module.client_vpc.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.client_dhcp_options.id
}

# Route53 configuration
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

# Route53 Resolver
module "resolver" {
  source         = "./modules/resolver"
  resolver_sg_id = module.security_groups.resolver_endpoint_sg_id
  subnet_id_1    = module.app_vpc.private_subnet_ids[2]
  subnet_id_2    = module.app_vpc.private_subnet_ids[3]
  providers = {
    aws = aws.us-east-1
  }
}

# 11. Client EC2 instance
module "ec2_client" {
  source               = "./modules/ec2-client"
  ami_id               = data.external.ami_us_east_2.result.ami_id
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
  depends_on = [
    aws_vpc_dhcp_options_association.client_vpc_dhcp_assoc,
    aws_route.to_app_vpc
  ]
}
