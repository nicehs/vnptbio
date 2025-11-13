output "cluster_name" {
  value = aws_eks_cluster.biocenter_cluster.name
}

output "cluster_arn" {
  value = aws_eks_cluster.biocenter_cluster.arn
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
