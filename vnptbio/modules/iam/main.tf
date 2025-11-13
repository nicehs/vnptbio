# -----------------------------------------------------------------------------
# IAM Role and Policy for EKS (or general usage)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "registry_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

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
  name = var.biocenter_cluster_name
}

# resource "aws_iam_policy" "terraform_kms" {
#   name        = "Terraform-KMS-Permissions"
#   description = "IAM policy for Terraform to manage KMS keys for EKS"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = [
#           "kms:CreateKey",
#           "kms:DescribeKey",
#           "kms:ListAliases",
#           "kms:TagResource",
#           "kms:CreateAlias",
#           "kms:EnableKeyRotation",
#           "kms:ScheduleKeyDeletion",
#           "kms:UpdateAlias"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_policy" "eks_cloudwatch_logs" {
#   name        = "eks-cloudwatch-logs"
#   description = "Allow EKS to create CloudWatch Log Groups with tags"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents",
#           "logs:DescribeLogGroups",
#           "logs:DescribeLogStreams",
#           "logs:TagResource",
#           "logs:PutRetentionPolicy",
#           "logs:ListTagsForResource"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_user_policy_attachment" "attach_cloudwatch_logs" {
#   user       = "terraform"
#   policy_arn = aws_iam_policy.eks_cloudwatch_logs.arn
# }


# resource "aws_iam_user_policy_attachment" "terraform_kms_attach" {
#   user       = "terraform"                # Replace with your IAM username
#   policy_arn = aws_iam_policy.terraform_kms.arn
# }

