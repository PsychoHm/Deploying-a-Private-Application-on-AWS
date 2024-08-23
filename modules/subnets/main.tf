resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                   = var.private_subnet_count
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + var.public_subnet_count)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.vpc_name}-private-${count.index + 1}"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}