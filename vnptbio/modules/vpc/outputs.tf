# Output VPC ID
output "vpc_id" {
  value = aws_vpc.main.id
}

# Output private subnet IDs
output "private_subnet_ids" {
  value = aws_subnet.eks[*].id
}

# Output public subnet IDs
output "public_subnets" {
  value = [aws_subnet.public.id]
}

# Security group for cluster
output "cluster_sg_id" {
  value = aws_security_group.eks_cluster_sg.id
}

# Security group for nodes
output "nodes_sg_id" {
  value = aws_security_group.eks_nodes_sg.id
}
