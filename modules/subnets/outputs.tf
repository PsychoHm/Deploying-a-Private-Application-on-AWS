output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
output "private_subnet_cidr" {
  value = aws_subnet.client_private_subnet.cidr_block # Adjust this based on your actual subnet resource
}