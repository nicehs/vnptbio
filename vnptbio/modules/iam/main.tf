# -----------------------------------------------------------------------------
# IAM Role and Policy for EKS (or general usage)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = var.assume_role_policy

  tags = merge(
    var.tags,
    {
      Module = "iam"
    }
  )
}

resource "aws_iam_policy" "this" {
  count  = var.create_policy ? 1 : 0
  name   = var.policy_name
  policy = var.policy_document

  tags = merge(
    var.tags,
    {
      Module = "iam"
    }
  )
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = var.create_policy ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[0].arn
}

# Optional: Attach managed policies
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)
  role     = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_policy" "terraform_kms" {
  name        = "Terraform-KMS-Permissions"
  description = "IAM policy for Terraform to manage KMS keys for EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:ListAliases",
          "kms:TagResource",
          "kms:CreateAlias",
          "kms:EnableKeyRotation",
          "kms:ScheduleKeyDeletion",
          "kms:UpdateAlias"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "eks_cloudwatch_logs" {
  name        = "eks-cloudwatch-logs"
  description = "Allow EKS to create CloudWatch Log Groups with tags"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:TagResource",
          "logs:PutRetentionPolicy",
          "logs:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_cloudwatch_logs" {
  user       = "terraform"
  policy_arn = aws_iam_policy.eks_cloudwatch_logs.arn
}


resource "aws_iam_user_policy_attachment" "terraform_kms_attach" {
  user       = "terraform"                # Replace with your IAM username
  policy_arn = aws_iam_policy.terraform_kms.arn
}

