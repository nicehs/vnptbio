# =============================================================================
# EKS Infrastructure with Bastion Host (SSM Only, Custom Subnets)
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws         = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes  = { source = "hashicorp/kubernetes", version = "~> 2.23" }
    helm        = { source = "hashicorp/helm", version = "~> 2.11" }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.biocenter_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.biocenter_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.biocenter_cluster.token
  load_config_file       = false
}


provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.biocenter_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.biocenter_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.biocenter_cluster.token
    #load_config_file       = false
  }
}

# -----------------------------------------------------------------------------
# VPC + Custom Subnets
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.233.8.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "eks-vpc" }
}

# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.main.id
#   tags   = { Name = "eks-igw" }
# }

resource "aws_subnet" "eks" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(["10.233.8.128/26", "10.233.8.192/26"], count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name                                = "eks-subnet-${count.index}"
    "kubernetes.io/cluster/biocenter-cluster" = "owned"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id
#   tags   = { Name = "eks-public-rt" }
# }

# resource "aws_route" "public_internet_access" {
#   route_table_id         = aws_route_table.public.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.igw.id
# }

# resource "aws_route_table_association" "public_assoc" {
#   count          = length(aws_subnet.eks)
#   subnet_id      = aws_subnet.eks[count.index].id
#   route_table_id = aws_route_table.public.id
# }


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
# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------
resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "eks-cluster-sg" }
}

resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "EKS worker nodes SG"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "Allow nodes communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.233.8.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "eks-nodes-sg" }
}

resource "aws_security_group_rule" "allow_nodes_to_cluster_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  description              = "Allow nodes to talk to cluster"
}

resource "aws_security_group_rule" "allow_bastion_to_cluster_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
  description              = "Allow bastion host to connect to cluster"
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host (SSM only)"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "bastion-sg" }
}

# resource "aws_security_group" "license_server_sg" {
#   name        = "license-server-sg"
#   description = "Security group for license server"
#   vpc_id      = aws_vpc.main.id
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = { Name = "license-server-sg" }
# }

# -----------------------------------------------------------------------------
# License Server
# -----------------------------------------------------------------------------
# resource "aws_instance" "license-server" {
#   ami                  = data.aws_ami.amazon_linux.id
#   instance_type        = "t3.micro"
#   subnet_id            = aws_subnet.eks[0].id
#   key_name             = "eks-key"
#   security_groups      = [aws_security_group.license_server_sg.id]
#   tags                 = { Name = "license-server" }
# }

# resource "aws_security_group_rule" "bastion_to_license_server_ssh" {
#   type                     = "ingress"
#   from_port                = 22
#   to_port                  = 22
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.license_server_sg.id
#   source_security_group_id = aws_security_group.bastion_sg.id
#   description              = "Allow SSH from Bastion to License Server"
# }

# -----------------------------------------------------------------------------
# Bastion Host + License server (SSM only)
# -----------------------------------------------------------------------------
# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode([
#       {
#         rolearn  = aws_iam_role.eks_node_role.arn
#         username = "system:node:{{EC2PrivateDNSName}}"
#         groups   = ["system:bootstrappers", "system:nodes"]
#       },
#       {
#         rolearn  = aws_iam_role.ssm_role.arn
#         username = "bastion"
#         groups   = ["system:masters"]
#       }
#     ])
#   }
# }

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_iam_instance_profile" "bastion_ssm_profile" {
  name = "bastion-ssm-profile"
  role = aws_iam_role.bastion_ssm_role.name
}

# resource "aws_iam_role" "ssm_role" {
#   name = "bastion-ssm-role"
#   assume_role_policy = data.aws_iam_policy_document.ssm_assume_role_policy.json
# }

data "aws_iam_policy_document" "ssm_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# resource "aws_iam_role_policy_attachment" "bastion_custom_eks_access" {
#   role       = aws_iam_role.bastion_ssm_role.name
#   policy_arn = "arn:aws:iam::136079915181:policy/EKSPlayground"
# }

resource "aws_instance" "bastion" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.eks[0].id
  security_groups      = [aws_security_group.bastion_sg.id]
  iam_instance_profile = aws_iam_instance_profile.bastion_ssm_profile.name
  tags                 = { Name = "bastion-host" }
  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    echo "Starting SSM agent setup..." >> /var/log/user-data.log
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    echo "SSM agent enabled and started" >> /var/log/user-data.log
    systemctl status amazon-ssm-agent >> /var/log/user-data.log

    # Update packages
    yum update -y || apt-get update -y

    # Install dependencies
    yum install -y unzip curl || apt-get install -y unzip curl

    # Install kubectl
    #KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/v1.34.1/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/bin/kubectl
    rm kubectl

    # Install AWS CLI v2
    yum remove awscli -y
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install --bin-dir /usr/bin --install-dir /usr/local/aws-cli

    # Update the package repository
    sudo yum update -y

    # Install Docker
    sudo yum install -y docker

    # Start Docker service
    sudo systemctl start docker

    # Enable Docker to start on boot
    sudo systemctl enable docker

    # Download the latest Helm binary (for Linux AMD64)
    curl -LO https://get.helm.sh/helm-v3.12.3-linux-amd64.tar.gz
    tar -zxvf helm-v3.12.3-linux-amd64.tar.gz
    sudo mv linux-amd64/helm /usr/bin/helm
    sudo chmod +x /usr/bin/helm
    helm version

    # Install eksctl
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" -o eksctl.tar.gz
    tar -xzf eksctl.tar.gz
    sudo mv eksctl /usr/bin/eksctl
    sudo chmod +x /usr/bin/eksctl
    eksctl version

    # Add kube config
    sudo aws eks --region ap-southeast-1 update-kubeconfig --name biocenter-cluster

    # Install registry
    sudo helm repo add twuni https://helm.twun.io
    sudo helm repo update
    sudo kubectl create serviceaccount registry-sa --namespace default
    sudo kubectl annotate serviceaccount registry-sa   eks.amazonaws.com/role-arn=arn:aws:iam::136079915181:role/eks-irsa-registry-role   --namespace default
    sudo helm upgrade --install docker-registry twuni/docker-registry   --namespace default   --create-namespace   --set persistence.enabled=false   --set service.type=NodePort   --set service.port=5000  \
    --set storage=s3   --set s3.region=ap-southeast-1   --set s3.bucket=registry-bio1   --set s3.encrypt=true   --set serviceAccount.create=false   --set serviceAccount.name=registry-sa   --set secrets.s3.secretKey=""

    # Install ingress
    sudo helm repo add eks https://aws.github.io/eks-charts
    sudo helm repo update
    sudo kubectl create serviceaccount aws-load-balancer-controller --namespace kube-system
    sudo kubectl annotate serviceaccount aws-load-balancer-controller   -n kube-system   eks.amazonaws.com/role-arn=arn:aws:iam::136079915181:role/eks-load-balancer-controller-role
    VPCID=`sudo aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eks-vpc" --query "Vpcs[0].VpcId" --output text`
    sudo helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller   -n kube-system   --set clusterName=biocenter-cluster   --set serviceAccount.create=false \
      --set region=ap-southeast-1   --set vpcId=$VPCID  --set serviceAccount.name=aws-load-balancer-controller
  EOF

  depends_on = [aws_eks_cluster.biocenter_cluster]
}

output "bastion_user_data" {
  value = aws_instance.bastion.user_data
}

resource "aws_iam_role" "bastion_ssm_role" {
  name = "bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "bastion_ssm_policy" {
  name        = "bastion-ssm-policy"
  description = "Policy for Bastion SSM Role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        Resource = "*"
      },
      {
        Sid    = "VisualEditor0",
        Effect = "Allow",
        Action = [
          "s3:*",
          "eks:*",
          "ec2:*",
          "iam:*",
          "ssm:StartSession",
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus",
          "ssm:DescribeInstanceInformation",
          "elasticloadbalancing:*",
          "rds:*"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "ssm:SendCommand",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "ssm:TerminateSession",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "cloudformation:ListStacks",
          "cloudformation:DescribeStacks",
          "cloudformation:CreateStack",
          "cloudformation:UpdateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStackEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_core" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = aws_iam_policy.bastion_ssm_policy.arn
}

# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.ssm"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = aws_subnet.eks[*].id
#   security_group_ids = [aws_security_group.bastion_sg.id]
#   private_dns_enabled = true
#   tags = { Name = "ssm-vpc-endpoint" }
# }

# -----------------------------------------------------------------------------
# SSM End Point
# -----------------------------------------------------------------------------
# resource "aws_security_group" "vpce" {
#   name   = "vpce-sg"
#   vpc_id = aws_vpc.main.id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.main.cidr_block]
#   }
# }

# resource "aws_iam_role_policy_attachment" "node_ssm_core" {
#   role       = aws_iam_role.eks_node_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.ssm"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = aws_subnet.eks[*].id
#   security_group_ids = [aws_security_group.vpce.id]
#   private_dns_enabled = true
#   tags = { Name = "ssm-vpc-endpoint" }
# }

# resource "aws_vpc_endpoint" "ssm_messages" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.ssmmessages"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = aws_subnet.eks[*].id
#   security_group_ids = [aws_security_group.vpce.id]
#   private_dns_enabled = true
#   tags = { Name = "ssmmessages-vpc-endpoint" }
# }

# resource "aws_vpc_endpoint" "ec2_messages" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.ec2messages"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = aws_subnet.eks[*].id
#   security_group_ids = [aws_security_group.vpce.id]
#   private_dns_enabled = true
#   tags = { Name = "ec2messages-vpc-endpoint" }
# }

# resource "aws_vpc_endpoint" "ec2" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.ec2"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = aws_subnet.eks[*].id
#   security_group_ids = [aws_security_group.vpce.id]
#   private_dns_enabled = true
#   tags = { Name = "ec2-vpc-endpoint" }
# }

# # ECR endpoints
# resource "aws_vpc_endpoint" "ecr_api" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = aws_subnet.eks[*].id
#   security_group_ids = [aws_security_group.vpce.id]
#   private_dns_enabled = true
# }

# resource "aws_vpc_endpoint" "ecr_dkr" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = aws_subnet.eks[*].id
#   security_group_ids = [aws_security_group.vpce.id]
#   private_dns_enabled = true
# }

# # EKS API endpoint (optional if cluster has private endpoint)
# resource "aws_vpc_endpoint" "eks" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.eks"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = aws_subnet.eks[*].id
#   security_group_ids = [aws_security_group.vpce.id]
#   private_dns_enabled = true
# }
# -----------------------------------------------------------------------------
# Network Load Balancer
# -----------------------------------------------------------------------------

# NLB 1 in subnet 0 (AZ1)
resource "aws_lb" "nlb_se1a" {
  name               = "nlb-se1a"
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb_sg.id]

  # Attach to first subnet
  subnet_mapping {
    subnet_id = aws_subnet.eks[0].id
    # Optional: assign a static IP in the subnet
    private_ipv4_address = "10.233.8.132"
  }

  enable_deletion_protection = false
  tags = { Name = "nlb-se1a" }
}

# NLB 2 in subnet 1 (AZ2)
resource "aws_lb" "nlb_se1b" {
  name               = "nlb-se1b"
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb_sg.id]

  # Attach to second subnet
  subnet_mapping {
    subnet_id = aws_subnet.eks[1].id
    # Optional static IP
    private_ipv4_address = "10.233.8.196"
  }

  enable_deletion_protection = false
  tags = { Name = "nlb-se1b" }
}

resource "aws_security_group" "nlb_sg" {
  name        = "nlb-shared-sg"
  description = "Security group for both NLBs"
  vpc_id      = aws_vpc.main.id

  # Allow inbound from the internet or your CIDR
  ingress {
    description = "Allow inbound to NLB (HTTP)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound to NLB (HTTPS)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_nlb_to_nodes" {
  type                     = "ingress"
  from_port                = 31730
  to_port                  = 31730
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.nlb_sg.id
  #cidr_blocks       = [aws_vpc.main.cidr_block]
  description              = "Allow traffic from both NLBs to NodePort"
}

resource "aws_lb_target_group" "nginx_tg_se1a" {
  name        = "nginx-tg-se1a"
  port        = 31730
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
  health_check {
    port     = "31730"
    protocol = "TCP"
  }
}

resource "aws_lb_target_group" "nginx_tg_se1b" {
  name        = "nginx-tg-se1b"
  port        = 31730
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
  health_check {
    port     = "31730"
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "az1_listener" {
  load_balancer_arn = aws_lb.nlb_se1a.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tg_se1a.arn
  }
}

resource "aws_lb_listener" "az2_listener" {
  load_balancer_arn = aws_lb.nlb_se1b.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tg_se1b.arn
  }
}

resource "aws_lb_target_group_attachment" "nginx_nodeport_se1a" {
  count            = length(data.aws_instances.eks_nodes.ids)
  target_group_arn = aws_lb_target_group.nginx_tg_se1a.arn
  target_id        = data.aws_instances.eks_nodes.ids[count.index]  # instance IDs
  port             = 31730
}

resource "aws_lb_target_group_attachment" "nginx_nodeport_se1b" {
  count            = length(data.aws_instances.eks_nodes.ids)
  target_group_arn = aws_lb_target_group.nginx_tg_se1b.arn
  target_id        = data.aws_instances.eks_nodes.ids[count.index]  # instance IDs
  port             = 31730
}

data "aws_instances" "eks_nodes" {
  instance_tags = {
    "kubernetes.io/cluster/biocenter-cluster" = "owned"
  }
}
# -----------------------------------------------------------------------------
# Dcoker registry
# -----------------------------------------------------------------------------
# resource "helm_release" "docker_registry" {
#   name       = "docker-registry"
#   repository = "https://helm.twun.io"
#   chart      = "docker-registry"
#   namespace  = "default"

#   values = [
#     yamlencode({
#       storage = {
#         type = "s3"
#         s3 = {
#           region = var.aws_region
#           bucket = aws_s3_bucket.registry_bio.bucket
#           encrypt = true
#         }
#       }

#       persistence = {
#         enabled = false
#       }

#       service = {
#         type = "ClusterIP" # Or "LoadBalancer" if you want external access
#         port = 5000
#       }

#       serviceAccount = {
#         create = false
#         name   = "registry-sa"  # This service account must be annotated with IRSA role
#       }
#     })
#   ]

#   depends_on = [aws_eks_cluster.biocenter_cluster]
# }

# -----------------------------------------------------------------------------
# EKS Cluster + Node Group
# -----------------------------------------------------------------------------
resource "aws_eks_cluster" "biocenter_cluster" {
  name     = "biocenter-cluster"
  role_arn = aws_iam_role.eks_role.arn
  vpc_config {
    subnet_ids         = aws_subnet.eks[*].id
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = false
  }
}

resource "aws_launch_template" "eks_nodes_group1" {
  name_prefix   = "eks-nodes-group1-"
  instance_type = "t3.medium"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.eks_nodes_sg.id]
  }
}

resource "aws_launch_template" "eks_nodes_group2" {
  name_prefix   = "eks-nodes-group2-"
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.eks_nodes_sg.id]
  }
}

resource "aws_eks_node_group" "vnpt_node_group1" {
  cluster_name    = aws_eks_cluster.biocenter_cluster.name
  node_group_name = "vnpt-node-group1"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.eks[*].id

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  launch_template {
    id      = aws_launch_template.eks_nodes_group1.id
    version = "$Latest"
  }

  # remote_access {
  #   ec2_ssh_key               = var.ssh_key_name
  #   source_security_group_ids = [aws_security_group.bastion_sg.id]
  # }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    Name = "vnpt-node-group1"
    "kubernetes.io/cluster/biocenter-cluster" = "owned"
  }
}

resource "aws_eks_node_group" "vnpt_node_group2" {
  cluster_name    = aws_eks_cluster.biocenter_cluster.name
  node_group_name = "vnpt-node-group2"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.eks[*].id

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  launch_template {
    id      = aws_launch_template.eks_nodes_group2.id
    version = "$Latest"
  }

  # remote_access {
  #   ec2_ssh_key               = var.ssh_key_name
  #   source_security_group_ids = [aws_security_group.bastion_sg.id]
  # }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    Name = "vnpt-node-group2"
    "kubernetes.io/cluster/biocenter-cluster" = "owned"
  } 
}

resource "aws_security_group_rule" "bastion_to_nodes_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
  description              = "Allow SSH from Bastion to EKS nodes"
}

# -----------------------------------------------------------------------------
# Service link role
# -----------------------------------------------------------------------------
# Create the service-linked role for ELB
resource "aws_iam_service_linked_role" "elb" {
  aws_service_name = "elasticloadbalancing.amazonaws.com"
  # AWS automatically attaches the AWSElasticLoadBalancingServiceRolePolicy policy.
  # No need to attach it manually; it’s managed by AWS.
}

# # (Optional) — if you want to explicitly attach the AWS managed policy yourself:
# data "aws_iam_policy" "elb_service_role_policy" {
#   arn = "arn:aws:iam::aws:policy/aws-service-role/AWSElasticLoadBalancingServiceRolePolicy"
# }

# resource "aws_iam_role_policy_attachment" "elb_service_role_attach" {
#   role       = aws_iam_service_linked_role.elb.name
#   policy_arn = data.aws_iam_policy.elb_service_role_policy.arn
# }

# Service-linked role for Amazon EKS control plane
resource "aws_iam_service_linked_role" "eks" {
  aws_service_name = "eks.amazonaws.com"
}

# Service-linked role for Amazon EKS nodegroups
resource "aws_iam_service_linked_role" "eks_nodegroup" {
  aws_service_name = "eks-nodegroup.amazonaws.com"
}

# Service-linked role for Auto Scaling
resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}

# Service-linked role for Amazon RDS
resource "aws_iam_service_linked_role" "rds" {
  aws_service_name = "rds.amazonaws.com"
}

# # Service-linked role for AWS Trusted Advisor
# resource "aws_iam_service_linked_role" "trusted_advisor" {
#   aws_service_name = "trustedadvisor.amazonaws.com"
# }

# # Service-linked role for AWS Support
# resource "aws_iam_service_linked_role" "support" {
#   aws_service_name = "support.amazonaws.com"
# }
# -----------------------------------------------------------------------------
# Initialize module in EKS
# -----------------------------------------------------------------------------
data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.biocenter_cluster.name
}

# Fetch the OIDC provider for the cluster
data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer

  depends_on = [aws_iam_openid_connect_provider.eks]
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0ecd4e0e3"]
}

# IAM Policy for S3 access
resource "aws_iam_policy" "registry_s3_access" {
  name        = "registry-s3-access"
  description = "Allow S3 access to registry-bio1 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
        ],
        Resource = [
          "arn:aws:s3:::registry-bio1",
          "arn:aws:s3:::registry-bio1/*"
        ]
      }
    ]
  })
}

# IAM Role for IRSA with trust policy
resource "aws_iam_role" "registry_irsa_role" {
  name = "eks-irsa-registry-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:default:registry-sa"
          }
        }
      }
    ]
  })
  depends_on = [aws_iam_openid_connect_provider.eks]
}

# Attach the S3 access policy to the IRSA role
resource "aws_iam_role_policy_attachment" "attach_registry_s3_access" {
  role       = aws_iam_role.registry_irsa_role.name
  policy_arn = aws_iam_policy.registry_s3_access.arn
}

# IAM Policy for S3 access
resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Allow EKS control ELB"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "acm:DescribeCertificate",
        "acm:ListCertificates",
        "acm:GetCertificate"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAddresses",
        "ec2:DescribeInstances",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVpcs",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DescribeRouteTables",
        "ec2:DescribeAvailabilityZones"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:AddListenerCertificates",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeListenerCertificates",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:DescribeSSLPolicies",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:RemoveListenerCertificates",
        "elasticloadbalancing:RemoveTags",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:SetWebAcl",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeListenerAttributes"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateServiceLinkedRole",
        "iam:GetServerCertificate",
        "iam:ListServerCertificates",
        "iam:GetRole"
],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cognito-idp:DescribeUserPoolClient"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "waf-regional:GetWebACLForResource",
        "waf-regional:GetWebACL",
        "waf-regional:AssociateWebACL",
        "waf-regional:DisassociateWebACL"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "tag:GetResources",
        "tag:TagResources"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "shield:GetSubscriptionState",
        "shield:DescribeProtection",
        "shield:CreateProtection",
        "shield:DeleteProtection",
        "shield:DescribeSubscription"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

# IAM Role for IRSA with trust policy
resource "aws_iam_role" "eks-load-balancer-controller-role" {
  name = "eks-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
  depends_on = [aws_iam_openid_connect_provider.eks]
}

# Attach the S3 access policy to the IRSA role
resource "aws_iam_role_policy_attachment" "attach_AWSLoadBalancerControllerIAMPolicy" {
  role       = aws_iam_role.eks-load-balancer-controller-role.name
  policy_arn = aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn
}

resource "aws_iam_role_policy_attachment" "cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_eks_cluster_auth" "biocenter_cluster" {
  name = aws_eks_cluster.biocenter_cluster.name
}

# -----------------------------------------------------------------------------
# IAM Roles
# -----------------------------------------------------------------------------
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "bastion_eks" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# -----------------------------------------------------------------------------
# S3
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "registry_bio" {
  bucket = "registry-bio1"  # Must be globally unique

  tags = {
    Name        = "registry-bio1"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.registry_bio.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# RDS
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.eks[*].id

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "Allow PostgreSQL from EKS nodes"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    #security_groups  = [aws_security_group.eks_nodes_sg.id]  # Allow EKS nodes SG
    cidr_blocks = ["10.233.8.128/26", "10.233.8.192/26"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

resource "aws_db_instance" "postgres" {
  identifier              = "postgres"
  engine                  = "postgres"
  engine_version          = "15.13"  # pick your version
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp2"
  username                = "adminuser"
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false
  deletion_protection     = false
  backup_retention_period = 7

  tags = {
    Name = "postgres"
  }
}

variable "db_password" {
  description = "The password for the PostgreSQL RDS instance"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Allow EKS access RDS and S3
# -----------------------------------------------------------------------------
# Attach IAM policies to your EKS Node Group Role
resource "aws_iam_role_policy_attachment" "node_AmazonS3ReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "node_AmazonRDSFullAccess" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "my-project"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "node_instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}

variable "node_desired_size" {
  description = "Desired worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Max worker nodes"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "Min worker nodes"
  type        = number
  default     = 1
}

variable "allowed_ingress_ssh_cidr" {
  description = "CIDR allowed to access ingress TCP SSH (2222). Set to your bastion/public IP or office IP."
  type        = string
  default     = "0.0.0.0/0" # CHANGE this to a safer CIDR (e.g. "203.0.113.5/32")
}

variable "ssh_key_name" {
  description = "EC2 key pair name used to SSH into worker nodes"
  type        = string
}