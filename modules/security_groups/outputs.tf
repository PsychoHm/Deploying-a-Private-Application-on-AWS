output "app_vpc_sg_id" {
  value = aws_security_group.app_vpc_sg.id
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "resolver_endpoint_sg_id" {
  value = aws_security_group.resolver_endpoint_sg.id
}

output "cgw_sg_id" {
  value = aws_security_group.cgw_sg.id
}

output "client_sg_id" {
  value = aws_security_group.client_sg.id
}

output "elasticache_sg_id" {
  value       = aws_security_group.elasticache_sg.id
  description = "ID of the ElastiCache security group"
}