terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.7.0"
    }
  }
}

provider "aws" {
  alias  = "us-east-2"
  region = "us-east-2"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "client_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.client_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 10)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Client-VPC-Public-Subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.client_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 20)
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Client-VPC-Private-Subnet"
  }
}

resource "aws_internet_gateway" "client_igw" {
  vpc_id = aws_vpc.client_vpc.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.client_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.client_igw.id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.client_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "${var.vpc_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "${var.vpc_name}-nat-gw"
  }
  depends_on = [aws_internet_gateway.client_igw]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [aws_vpc.client_vpc]

  create_duration = "30s"
}

# EIP for CGW
resource "aws_eip" "cgw_eip" {
  provider = aws.us-east-2
  vpc      = true
  tags     = { Name = "CGW-EIP" }
}