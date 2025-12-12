# output "nlb_arns" {
#   value = { for k, v in aws_lb.this : k => v.arn }
# }

# output "target_group_arns" {
#   value = { for k, v in aws_lb_target_group.this : k => v.arn }
# }

# output "security_group_id" {
#   value = aws_security_group.this.id
# }
