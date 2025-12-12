output "secondary_cidr_block" {
  description = "Secondary CIDR block associated with VPC"
  value       = aws_vpc_ipv4_cidr_block_association.secondary.cidr_block
}

output "secondary_subnet_ids" {
  description = "Map of AZ to secondary subnet IDs"
  value       = { for k, v in aws_subnet.secondary : k => v.id }
}

output "secondary_subnets" {
  description = "Map of secondary subnet details"
  value       = aws_subnet.secondary
}

output "secondary_route_table_id" {
  description = "Route table ID for secondary subnets"
  value       = aws_route_table.secondary.id
}