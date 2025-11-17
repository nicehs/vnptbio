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

output "eks_cluster_sg_id" {
  value = aws_security_group.eks_cluster_sg.id
}

output "eks_nodes_sg_id" {
  value = aws_security_group.eks_nodes_sg.id
}

# output "bastion_public_ip" {
#   value = aws_instance.bastion.public_ip
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

output "aws_eks_cluster_biocenter_cluster" {
  value = aws_eks_cluster.biocenter_cluster
}
