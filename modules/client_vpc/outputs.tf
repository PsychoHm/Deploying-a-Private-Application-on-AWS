output "vpc_id" {
  value = aws_vpc.client_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.client_vpc.cidr_block
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "public_subnet_cidr" {
  value = aws_subnet.public_subnet.cidr_block
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "private_route_table_id" {
  value = aws_route_table.private_rt.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat_gw.id
}