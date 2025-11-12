output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = data.aws_iam_openid_connect_provider.this.arn
}

output "node_group_names" {
  description = "Names of the created node groups"
  value       = [for ng in aws_eks_node_group.this : ng.node_group_name]
}
