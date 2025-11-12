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

# -----------------------------------------------------------------------------
# IAM Module
# -----------------------------------------------------------------------------

module "iam" {
  source = "./modules/iam"

  role_name          = "xplat-eks-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json

  create_policy   = true
  policy_name     = "xplat-eks-policy"
  policy_document = data.aws_iam_policy_document.eks_policy.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  ]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# EKS Module
# -----------------------------------------------------------------------------

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "vnpt-bio"
  cluster_version = "1.29"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  create_iam_role           = true
  #create_iam_oidc_provider  = true

  eks_managed_node_groups = {
    vnpt_node_group1 = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.micro"]
    }
    vnpt_node_group2 = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t2.micro"]
    }
  }

  # Skip creating new KMS key by specifying existing one
  # cluster_encryption_config = [
  #   {
  #     resources = ["secrets"]
  #     provider  = {
  #       key_arn = "arn:aws:kms:ap-southeast-1:136079915181:key/my-keypair"
  #     }
  #   }
  # ]
  cluster_enabled_log_types = []  # Disable CloudWatch logs
  tags = local.common_tags
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

module "nlb" {
  source = "./modules/nlb"

  name        = "xplat-nlb"
  internal    = false
  subnets     = module.vpc.public_subnets
  vpc_id      = module.vpc.vpc_id

  target_group_name = "xplat-nlb-tg"
  target_port       = 80
  listener_port     = 80

  target_attachments = {
    "bastion" = {
      target_id = module.ec2.bastion_id
      port      = 22
    }
  }

  tags = local.common_tags
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
