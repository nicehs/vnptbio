# output "license_server_id" {
#   description = "ID of the license server instance"
#   value       = aws_instance.this.id
# }

# output "license_server_private_ip" {
#   description = "Private IP address of the license server"
#   value       = aws_instance.this.private_ip
# }

# output "license_server_public_ip" {
#   description = "Public IP (EIP if created) of the license server"
#   value       = var.create_eip ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
# }

# output "license_server_sg_id" {
#   description = "Security group ID of the license server"
#   value       = aws_security_group.this.id
# }

output "license_server_sg_id" {
  description = "Security group ID of the license server"
  value       = aws_security_group.license_server_sg.id
}