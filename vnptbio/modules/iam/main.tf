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
