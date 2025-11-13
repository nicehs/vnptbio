# output "eks_role" {
#   description = "The name of the IAM role"
#   value       = aws_iam_role.eks_role.name
# }

# output "role_arn" {
#   description = "The ARN of the IAM role"
#   value       = aws_iam_role.role_name.arn
# }

# output "policy_arn" {
#   description = "The ARN of the custom policy, if created"
#   value       = try(aws_iam_policy.this[0].arn, null)
# }

output "eks_role_arn" {
  value = aws_iam_role.eks_role.arn
}

output "node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "eks_node_role_arn" {
  value = aws_iam_role.eks_role.arn
}