# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = var.vpc_name }
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.vpc_name}-igw" }
}

# -----------------------------------------------------------------------------
# Public Subnet
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets_cidrs
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name                                      = "${var.vpc_name}-public-subnet"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                  = "1"
  }
}

# -----------------------------------------------------------------------------
# Private Subnets
# -----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name                                = "eks-subnet-${count.index}"
    "kubernetes.io/cluster/biocenter-cluster" = "owned"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# -----------------------------------------------------------------------------
# NAT Gateway
# -----------------------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.vpc_name}-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags          = { Name = "${var.vpc_name}-nat" }
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.vpc_name}-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.vpc_name}-private-rt" }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {}
