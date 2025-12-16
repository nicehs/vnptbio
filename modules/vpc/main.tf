# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Associate secondary CIDR block to existing VPC
resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  vpc_id     = var.vpc_id
  cidr_block = "100.64.0.0/16"
}

# Create secondary subnets for pod networking (one per AZ)
resource "aws_subnet" "secondary" {
  for_each = toset(slice(data.aws_availability_zones.available.names, 0, 2))

  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet("100.64.0.0/16", 9, index(data.aws_availability_zones.available.names, each.value))
  availability_zone = each.value

  tags = merge(
    var.tags,
    {
      Name                                        = "eks-secondary-private-${each.value}"
      "kubernetes.io/role/internal-elb"           = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )

  depends_on = [aws_vpc_ipv4_cidr_block_association.secondary]
}

# Route table for secondary subnets
resource "aws_route_table" "secondary" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "eks-secondary-private-route-table"
    }
  )
}

# Associate route table with secondary subnets
resource "aws_route_table_association" "secondary" {
  for_each = aws_subnet.secondary

  subnet_id      = each.value.id
  route_table_id = aws_route_table.secondary.id
}

# VPC Endpoints routes (if using VPC endpoints for private connectivity)
resource "aws_route" "secondary_vpce" {
  count = var.vpc_endpoint_id != null ? 1 : 0

  route_table_id         = aws_route_table.secondary.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = var.vpc_endpoint_id
}