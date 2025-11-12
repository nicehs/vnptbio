# -----------------------------------------------------------------------------
# VPC Module
# -----------------------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  # name            = "xplat-vpc"
  #project_name    = "vnpt-bio"
  azs             = ["ap-southeast-1a", "ap-southeast-1b"]
  cidr            = "10.233.8.0/24"
  public_subnets  = ["10.233.8.0/26"]
  private_subnets = ["10.233.8.128/26", "10.233.8.192/26"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.common_tags
}
#-----------------------------
# Internet Gateway
#-----------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "eks-igw" }
}

#-----------------------------
# Public Subnet for NAT Gateway
#-----------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.233.8.0/26"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {  
    Name                                = "eks-public-subnet"
    "kubernetes.io/cluster/biocenter-cluster" = "owned"
    "kubernetes.io/role/elb" = "1"
  }
}

#-----------------------------
# Elastic IP for NAT Gateway
#-----------------------------
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = { Name = "eks-nat-eip" }
}

#-----------------------------
# NAT Gateway in Public Subnet
#-----------------------------
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = { Name = "eks-nat-gateway" }
}

#-----------------------------
# Route Table for Public Subnet
#-----------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "eks-public-rt" }
}

# Route to IGW for public subnet
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate public subnet with its route table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#-----------------------------
# Route Table for Private Subnets
#-----------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "eks-private-rt" }
}

# Route to NAT Gateway for private subnets
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.eks)
  subnet_id      = aws_subnet.eks[count.index].id
  route_table_id = aws_route_table.private.id
}

# # Public Subnet (for NAT / bastion)
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.this.id
#   cidr_block              = var.public_subnet_cidr
#   availability_zone       = var.azs[0]
#   map_public_ip_on_launch = true

#   tags = merge(
#     {
#       Name = "${var.project_name}-public-subnet"
#     },
#     var.tags
#   )
# }

# # Private Subnets (for EKS nodes / workloads)
# resource "aws_subnet" "private" {
#   for_each = toset(var.private_subnet_cidrs)

#   #project_name      = "vnpt-bio"
#   vpc_id            = aws_vpc.this.id
#   cidr_block        = each.value
#   availability_zone = element(var.azs, index(var.private_subnet_cidrs, each.value))

#   tags = merge(
#     {
#       Name = "${var.project_name}-private-${index(var.private_subnet_cidrs, each.value)}"
#     },
#     var.tags
#   )
# }

# # Internet Gateway (for outbound public access)
# resource "aws_internet_gateway" "this" {
#   vpc_id = aws_vpc.this.id

#   tags = merge(
#     {
#       Name = "${var.project_name}-igw"
#     },
#     var.tags
#   )
# }

# # Elastic IP for NAT
# resource "aws_eip" "nat" {
#   domain = "vpc"

#   tags = merge(
#     {
#       Name = "${var.project_name}-nat-eip"
#     },
#     var.tags
#   )
# }

#-----------------------------
# Public Subnet for NAT Gateway
#-----------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.233.8.0/26"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {  
    Name                                = "eks-public-subnet"
    "kubernetes.io/cluster/biocenter-cluster" = "owned"
    "kubernetes.io/role/elb" = "1"
  }
}

#-----------------------------
# Elastic IP for NAT Gateway
#-----------------------------
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = { Name = "eks-nat-eip" }
}

# NAT Gateway
# resource "aws_nat_gateway" "this" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public.id

#   tags = merge(
#     {
#       Name = "${var.project_name}-nat"
#     },
#     var.tags
#   )
# }

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      Name = "${var.project_name}-public-rt"
    },
    var.tags
  )
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(
    {
      Name = "${var.project_name}-private-rt"
    },
    var.tags
  )
}

# Route Table Associations
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
