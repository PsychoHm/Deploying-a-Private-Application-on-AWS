output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.this.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "vpn_gateway_id" {
  description = "The ID of the VPN Gateway"
  value       = aws_vpn_gateway.this.id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = aws_route_table.private.id
}

output "elasticache_subnet_ids" {
  value = aws_subnet.elasticache[*].id
}