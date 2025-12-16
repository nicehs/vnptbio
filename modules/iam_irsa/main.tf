#################################
# Fetch cluster for OIDC URL
#################################
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "tls_certificate" "oidc" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

#################################
# OIDC Provider
#################################
resource "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    data.tls_certificate.oidc.certificates[0].sha1_fingerprint
  ]
}

#################################
# Example IRSA Role — Registry
#################################
resource "aws_iam_role" "registry_irsa" {
  name = "eks-irsa-registry"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:registry:registry-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "registry_s3_access" {
  role       = aws_iam_role.registry_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
