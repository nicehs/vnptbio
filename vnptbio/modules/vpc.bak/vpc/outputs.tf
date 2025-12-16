# Output VPC ID
output "vpc_id" {
  value = aws_vpc.main.id
}

# Output private subnet IDs
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

# Output public subnet IDs
output "public_subnets" {
  value = [aws_subnet.public.id]
}

# # Security group for cluster
# output "cluster_sg_id" {
#   value = var.eks_cluster_sg_id
# }
