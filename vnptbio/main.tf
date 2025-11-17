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
# module "vpc" {
#   source = "./modules/vpc"

#   vpc_cidr_block = "10.233.8.0/24"
#   availability_zones = "ap-southeast-1"
#   cluster_name = "biocenter-cluster"
# }

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
  subnet_ids     = [var.subnet_id_app_a, var.subnet_id_app_b]
  vpc_id = var.vpc_id
  node_AmazonEKSWorkerNodePolicy = module.iam.node_AmazonEKSWorkerNodePolicy
  node_AmazonEKS_CNI_Policy      = module.iam.node_AmazonEKS_CNI_Policy
  node_AmazonEC2ContainerRegistryReadOnly = module.iam.node_AmazonEC2ContainerRegistryReadOnly
  bastion_sg_id = module.ec2.bastion_sg_id
}


# -----------------------------------------------------------------------------
# Bastion Host Module
# -----------------------------------------------------------------------------

module "ec2" {
  source = "./modules/ec2"

  name              = "license-server"
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id_app_a
  ami_id            = data.aws_ami.amazon_linux.id
  aws_eks_cluster_biocenter_cluster = module.eks.aws_eks_cluster_biocenter_cluster
  instance_type     = "t3.micro"
  bastion_ssm_profile_name = module.iam.bastion_ssm_profile_name
  bastion_ssm_role_name    = module.iam.bastion_ssm_role_name

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

  vpc_id          = var.vpc_id
  eks_nodes_sg_id = module.eks.eks_nodes_sg_id

  subnet_mapping = {
    "nlb-se1a" = {
      subnet_id  = element([var.subnet_id_app_a, var.subnet_id_app_b], 0)
      private_ip = "10.233.8.132"
    },
    "nlb-se1b" = {
      subnet_id  = element([var.subnet_id_app_a, var.subnet_id_app_b], 1)
      private_ip = "10.233.8.196"
    }
  }
}

# -----------------------------------------------------------------------------
# S3
# -----------------------------------------------------------------------------
module "s3" {
  source = "./modules/s3"

  environment = var.environment
  project_name     = var.project_name
}

# -----------------------------------------------------------------------------
# RDS
# -----------------------------------------------------------------------------
module "rds" {
  source = "./modules/rds"

  subnet_ids     = [var.subnet_id_app_a, var.subnet_id_app_b]
  db_password    = var.db_password
  vpc_id = var.vpc_id
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
    Project     = "vnpt-biocenter"
    ManagedBy   = "Terraform"
  }
}
