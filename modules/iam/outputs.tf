output "role_name" {
  description = "The name of the IAM role"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "policy_arn" {
  description = "The ARN of the custom policy, if created"
  value       = try(aws_iam_policy.this[0].arn, null)
}
