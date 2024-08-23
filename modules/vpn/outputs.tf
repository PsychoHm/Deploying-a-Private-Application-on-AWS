output "vgw_id" {
  description = "The ID of the VPN Gateway"
  value       = local.vgw_id
}

output "cgw_id" {
  description = "The ID of the Customer Gateway"
  value       = aws_customer_gateway.cgw.id
}

output "vpn_connection_id" {
  description = "The ID of the VPN Connection"
  value       = length(aws_vpn_connection.main) > 0 ? aws_vpn_connection.main[0].id : null
}
