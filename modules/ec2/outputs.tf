# output "bastion_id" {
#   description = "ID of the bastion instance"
#   value       = aws_instance.this.id
# }

# output "bastion_private_ip" {
#   description = "Private IP address of the bastion"
#   value       = aws_instance.this.private_ip
# }

# output "bastion_public_ip" {
#   description = "Public IP (EIP if created) of the bastion"
#   value       = var.create_eip ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
# }

# output "bastion_sg_id" {
#   description = "Security group ID of the bastion"
#   value       = aws_security_group.this.id
# }

output "bastion_sg_id" {
  description = "Security group ID of the bastion"
  value       = aws_security_group.bastion_sg.id
}