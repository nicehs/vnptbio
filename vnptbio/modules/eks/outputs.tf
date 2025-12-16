output "cluster_name" {
  value = aws_eks_cluster.vnpt_cluster.name
}

output "cluster_arn" {
  value = aws_eks_cluster.vnpt_cluster.arn
}

output "vnpt_node_group1" {
  value = aws_eks_node_group.vnpt_node_group1.node_group_name
}

output "vnpt_node_group2" {
  value = aws_eks_node_group.vnpt_node_group2.node_group_name
}

output "node_group_arns" {
  value = [
    aws_eks_node_group.vnpt_node_group1.arn,
    aws_eks_node_group.vnpt_node_group2.arn
  ]
}

output "eks_cluster_sg_id" {
  value = aws_security_group.eks_cluster_sg.id
}

output "eks_nodes_sg_id" {
  value = aws_security_group.eks_nodes_sg.id
}

# output "license_server_public_ip" {
#   value = aws_instance.license server.public_ip
# }

output "launch_template_group1_id" {
  value = aws_launch_template.eks_nodes_group1.id
}

output "launch_template_group2_id" {
  value = aws_launch_template.eks_nodes_group2.id
}

output "subnet_ids" {
  value = var.subnet_ids
}

output "aws_eks_cluster_vnpt_cluster" {
  value = aws_eks_cluster.vnpt_cluster
}

# output "vpc_cni_addon_version" {
#   description = "Version of VPC CNI addon installed"
#   value       = aws_eks_addon.vpc_cni.addon_version
# }

# output "vpc_cni_iam_role_arn" {
#   description = "IAM role ARN for VPC CNI pod identity"
#   value       = aws_iam_role.vpc_cni.arn
# }

# output "vpc_cni_iam_role_name" {
#   description = "IAM role name for VPC CNI"
#   value       = aws_iam_role.vpc_cni.name
# }

# output "vpc_cni_pod_identity_association_id" {
#   description = "Pod Identity Association ID for VPC CNI"
#   value       = aws_eks_pod_identity_association.vpc_cni.id
# }