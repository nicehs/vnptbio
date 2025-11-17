resource "aws_s3_bucket" "registry_bio" {
  bucket = "registry-bio1"  # Must be globally unique

  tags = {
    name        = "registry-bio1"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.registry_bio.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
