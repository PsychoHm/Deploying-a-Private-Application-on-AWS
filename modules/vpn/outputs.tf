output "vpn_connection_id" {
  description = "The ID of the VPN Connection"
  value       = aws_vpn_connection.main.id
}

output "vgw_id" {
  description = "The ID of the VPN Gateway"
  value       = aws_vpn_gateway.vgw.id
}
