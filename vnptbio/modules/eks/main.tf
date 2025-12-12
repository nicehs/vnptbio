# -----------------------------------------------------------------------------
# EKS Cluster + Node Group
# -----------------------------------------------------------------------------
resource "aws_eks_cluster" "vnpt_cluster" {
  name     = "vnpt-cluster"
  role_arn = var.eks_role_arn
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = false
  }
  upgrade_policy {
    support_type = "STANDARD"
  }
}

resource "aws_launch_template" "eks_nodes_group1" {
  name_prefix   = "eks-nodes-group1-"
  instance_type = "c5a.4xlarge"


  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.eks_nodes_sg.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"  # Root device for Amazon Linux 2
    
    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      iops                  = 3000
      throughput            = 125
    }
  }

}

resource "aws_launch_template" "eks_nodes_group2" {
  name_prefix   = "eks-nodes-group2-"
  instance_type = "c5a.xlarge"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.eks_nodes_sg.id]
  }
}

# resource "aws_launch_template" "eks_nodes_group3" {
#   name_prefix   = "eks-nodes-group3-"
#   instance_type = "c5a.xlarge"

#   network_interfaces {
#     associate_public_ip_address = false
#     security_groups             = [aws_security_group.eks_nodes_sg.id]
#   }
# }

resource "aws_eks_node_group" "vnpt_node_group1" {
  cluster_name    = aws_eks_cluster.vnpt_cluster.name
  node_group_name = "vnpt-node-group1"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = [var.subnet_ids[0]]

  capacity_type = "SPOT"

  scaling_config {
    desired_size = 1
    max_size     = 4
    min_size     = 1
  }

  launch_template {
    id      = aws_launch_template.eks_nodes_group1.id
    version = "$Latest"
  }

  # remote_access {
  #   ec2_ssh_key               = var.ssh_key_name
  #   source_security_group_ids = [aws_security_group.license_server_sg.id]
  # }

  depends_on = [
    var.node_AmazonEKSWorkerNodePolicy,
    var.node_AmazonEKS_CNI_Policy,
    var.node_AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    Name = "vnpt-node-group1"
    "kubernetes.io/cluster/vnpt-cluster" = "owned"
  }
}

resource "aws_eks_node_group" "vnpt_node_group2" {
  cluster_name    = aws_eks_cluster.vnpt_cluster.name
  node_group_name = "vnpt-node-group2"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = [var.subnet_ids[1]]

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
  #   source_security_group_ids = [aws_security_group.license_server_sg.id]
  # }

  depends_on = [
    var.node_AmazonEKSWorkerNodePolicy,
    var.node_AmazonEKS_CNI_Policy,
    var.node_AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    Name = "vnpt-node-group2"
    "kubernetes.io/cluster/vnpt-cluster" = "owned"
  } 
}

resource "aws_eks_node_group" "vnpt_node_group3" {
  cluster_name    = aws_eks_cluster.vnpt_cluster.name
  node_group_name = "vnpt-node-group3"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = [var.subnet_ids[0]]

  capacity_type = "SPOT"

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
  #   source_security_group_ids = [aws_security_group.license_server_sg.id]
  # }

  depends_on = [
    var.node_AmazonEKSWorkerNodePolicy,
    var.node_AmazonEKS_CNI_Policy,
    var.node_AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    Name = "vnpt-node-group3"
    "kubernetes.io/cluster/vnpt-cluster" = "owned"
  } 
}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id
  tags        = { Name = "eks-cluster-sg" }
}

resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "EKS worker nodes SG"
  vpc_id      = var.vpc_id
  ingress {
    description = "Allow nodes communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.233.8.0/24","100.64.0.0/16"]
  }
  ingress {
    description = "Allow nodes communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["10.233.8.0/24","100.64.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "eks-nodes-sg" }
}

resource "aws_security_group_rule" "allow_ip_to_node_22" {
  for_each                 = toset(local.allowed_ips)

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  cidr_blocks              = [each.key]
  description              = "Allow specific IP to SSH node"
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

locals {
  allowed_ips = [
    "10.2.130.136/32",
    "10.2.130.112/32",
    "10.2.130.78/32",
    "10.2.130.178/32",
    "10.2.130.88/32",
    "10.2.130.73/32",
  ]
}

resource "aws_security_group_rule" "allow_ip_to_cluster_443" {
  for_each                 = toset(local.allowed_ips)

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  cidr_blocks              = [each.key]
  description              = "Allow specific IP to access cluster"
}


resource "aws_security_group_rule" "allow_license_server_to_cluster_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = var.license_server_sg_id
  description              = "Allow license server to connect to cluster"
}

resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "vpc-endpoints-sg"
  description = "Allow nodes to access AWS PrivateLink endpoints"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.233.8.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EKS endpoint
resource "aws_vpc_endpoint" "eks" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.ap-southeast-1.eks"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [var.subnet_ids[1]]
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true
}

# EC2 API
# resource "aws_vpc_endpoint" "ec2" {
#   vpc_id             = var.vpc_id
#   service_name       = "com.amazonaws.ap-southeast-1.ec2"
#   vpc_endpoint_type  = "Interface"
#   subnet_ids         = var.subnet_ids
#   security_group_ids = [aws_security_group.vpc_endpoints_sg.id]
#   private_dns_enabled = true
# }

# ECR API
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.ap-southeast-1.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [var.subnet_ids[1]]
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true
}

# ECR Docker Registry
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.ap-southeast-1.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [var.subnet_ids[1]]
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true
}

# CloudWatch Logs
# resource "aws_vpc_endpoint" "logs" {
#   vpc_id             = var.vpc_id
#   service_name       = "com.amazonaws.ap-southeast-1.logs"
#   vpc_endpoint_type  = "Interface"
#   subnet_ids         = var.subnet_ids
#   security_group_ids = [aws_security_group.vpc_endpoints_sg.id]
#   private_dns_enabled = true
# }

# STS API
resource "aws_vpc_endpoint" "sts" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.ap-southeast-1.sts"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [var.subnet_ids[1]]
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = false
}

# # Data source to get current AWS region
# data "aws_region" "current" {}

# # Data source to get the latest VPC CNI addon version
# data "aws_eks_addon_version" "latest" {
#   addon_name         = "vpc-cni"
#   kubernetes_version = var.cluster_version
#   most_recent        = true
# }

# # IAM role for VPC CNI Pod Identity
# data "aws_iam_policy_document" "vpc_cni_assume_role" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["pods.eks.amazonaws.com"]
#     }

#     actions = [
#       "sts:AssumeRole",
#       "sts:TagSession"
#     ]
#   }
# }

# resource "aws_iam_role" "vpc_cni" {
#   name = "${var.cluster_name}-vpc-cni-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = { Federated = data.aws_iam_openid_connect_provider.oidc.arn }
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Condition = {
#         StringEquals = {
#           # replace with your OIDC issuer host path if needed
#           "${replace(data.aws_iam_openid_connect_provider.oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-node"
#         }
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "vpc_cni" {
#   role       = aws_iam_role.vpc_cni.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# }

# data "aws_eks_cluster" "cluster" {
#   name = aws_eks_cluster.vnpt_cluster.name
# }

# # You need the cluster OIDC provider data source; example:
# data "aws_iam_openid_connect_provider" "oidc" {
#   # set the correct OIDC provider url for your cluster
#   # optionally use aws_eks_cluster data to discover it
#   url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer  # adjust per module
# }

# # VPC CNI addon configuration
# resource "aws_eks_addon" "vpc_cni" {
#   cluster_name      = var.cluster_name
#   addon_name        = "vpc-cni"
#   addon_version     = data.aws_eks_addon_version.latest.version
#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"

#   configuration_values = jsonencode({
#     env = {
#       # Reference https://aws.github.io/aws-eks-best-practices/reliability/docs/networkmanagement/#cni-custom-networking
#       AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
#       ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"

#       # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
#       ENABLE_PREFIX_DELEGATION = "true"
#       WARM_PREFIX_TARGET       = "1"
#       WARM_IP_TARGET           = "5"
#       MINIMUM_IP_TARGET        = "3"
#     }
#     eniConfig = {
#       create  = true
#       region  = data.aws_region.current.name
#       subnets = {
#         for k, v in var.secondary_subnets : k => { id = v }
#       }
#     }
#   })

#   tags = var.tags

#   depends_on = [aws_eks_cluster.vnpt_cluster]
# }

# # Pod Identity Association for VPC CNI
# resource "aws_eks_pod_identity_association" "vpc_cni" {
#   cluster_name    = var.cluster_name
#   namespace       = "kube-system"
#   service_account = var.aws_vpc_cni_service_account_name
#   role_arn        = aws_iam_role.vpc_cni.arn

#   tags = var.tags

#   depends_on = [aws_eks_cluster.vnpt_cluster]
# }

# resource "kubernetes_service_account_v1" "aws_node" {
#   metadata {
#     name      = "aws-node"
#     namespace = "kube-system"
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.vpc_cni.arn
#     }
#   }

#   automount_service_account_token = true

#   # If the SA already exists and you do not want Terraform to fail, consider lifecycle ignore on certain changes.
#   lifecycle {
#     prevent_destroy = false
#   }
# }