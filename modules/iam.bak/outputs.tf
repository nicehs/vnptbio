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

# output "node_role_arn" {
#   value = aws_iam_role.eks_node_role.arn
# }

output "eks_node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "node_AmazonEKSWorkerNodePolicy" {
  value = aws_iam_role_policy_attachment.worker_node_policy.policy_arn
}

output "node_AmazonEKS_CNI_Policy" {
  value = aws_iam_role_policy_attachment.cni_policy.policy_arn
}

output "node_AmazonEC2ContainerRegistryReadOnly" {
  value = aws_iam_role_policy_attachment.registry_policy.policy_arn
}

output "bastion_ssm_role_name" {
  value = aws_iam_role.bastion_ssm_role.name
}

output "bastion_ssm_profile_name" {
  value = aws_iam_instance_profile.bastion_ssm_profile.name
}