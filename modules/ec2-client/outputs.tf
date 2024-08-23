output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.ec2_instance.id
}

output "private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.ec2_instance.private_ip
}

output "public_ip" {
  description = "The public IP address of the EC2 instance (if applicable)"
  value       = var.create_eip ? aws_eip.instance_eip[0].public_ip : aws_instance.ec2_instance.public_ip
}

output "network_interface_id" {
  description = "The ID of the primary network interface"
  value       = aws_instance.ec2_instance.primary_network_interface_id
}