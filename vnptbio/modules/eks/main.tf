# -----------------------------------------------------------------------------
# EKS Cluster + Node Group
# -----------------------------------------------------------------------------
resource "aws_eks_cluster" "biocenter_cluster" {
  name     = "biocenter-cluster"
  role_arn = var.eks_role_arn
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = false
  }
}

resource "aws_eks_node_group" "vnpt_node_group1" {
  cluster_name    = aws_eks_cluster.biocenter_cluster.name
  node_group_name = "vnpt-node-group1"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.subnet_ids

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
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.subnet_ids

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

resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_main_id
  tags        = { Name = "eks-cluster-sg" }
}

resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "EKS worker nodes SG"
  vpc_id      = var.vpc_main_id
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
  vpc_id      = var.vpc_main_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "bastion-sg" }
}