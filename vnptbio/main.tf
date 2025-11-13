# -----------------------------------------------------------------------------
# Terraform & Provider Configuration
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "xplat-hydro/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

###########################################
# VPC module
###########################################
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block = "10.233.8.0/24"
  availability_zones = "ap-southeast-1"
}

###########################################
# IAM module
###########################################
module "iam" {
  source = "./modules/iam"
  #cluster_name = "biocenter-cluster"
  role_name           = "eks-cluster-role"
  biocenter_cluster_name = module.eks.cluster_name
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

###########################################
# EKS module
###########################################
module "eks" {
  source = "./modules/eks"

  cluster_name  = "biocenter-cluster"
  eks_role_arn  = module.iam.eks_role_arn
  eks_node_role_arn = module.iam.eks_node_role_arn
  subnet_ids     = module.vpc.private_subnet_ids
  cluster_sg_id  = module.vpc.cluster_sg_id
  nodes_sg_id    = module.vpc.nodes_sg_id
  vpc_main_id = module.vpc.vpc_id
}


# -----------------------------------------------------------------------------
# Bastion Host Module
# -----------------------------------------------------------------------------

module "ec2" {
  source = "./modules/ec2"

  name              = "license-server"
  vpc_id            = module.vpc.vpc_id
  subnet_id         = element(module.vpc.public_subnets, 0)
  ami_id            = data.aws_ami.amazon_linux.id
  instance_type     = "t3.micro"
  allowed_ssh_cidrs = ["0.0.0.0/24"] # Example: office IP or VPN

  key_name        = "my-keypair"
  #create_key_pair = false
  create_eip      = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Network Load Balancer Module
# -----------------------------------------------------------------------------

data "aws_instances" "eks_nodes" {
  instance_tags = {
    "kubernetes.io/cluster/biocenter-cluster" = "owned"
  }
}

module "nlb" {
  source = "./modules/nlb"

  vpc_id          = module.vpc.vpc_id
  eks_nodes_sg_id = module.eks.cluster_security_group_id

  instance_ids = module.eks.node_instance_ids

  subnet_mappings = [
    {
      name       = "nlb-se1a"
      subnet_id  = element(module.vpc.private_subnet_ids, 0)
      private_ip = "10.233.8.132"
    },
    {
      name       = "nlb-se1b"
      subnet_id  = element(module.vpc.private_subnet_ids, 1)
      private_ip = "10.233.8.196"
    }
  ]
}




# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eks_policy" {
  statement {
    actions = [
      "ec2:Describe*",
      "elasticloadbalancing:*",
      "cloudwatch:*",
      "autoscaling:*",
      "logs:*"
    ]
    resources = ["*"]
  }
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  common_tags = {
    Environment = var.environment
    Project     = "xplat-hydro"
    ManagedBy   = "Terraform"
  }
}
