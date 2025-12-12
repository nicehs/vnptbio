resource "aws_s3_bucket" "registry_bio" {
  bucket = "registry-ekyc"  # Must be globally unique

  tags = {
    name        = "registry-ekyc"
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

resource "aws_s3_bucket" "tf_state" {
  bucket = "vnpt-ekyc-terraform-state"  # Must be globally unique

    tags = {
    name        = "vnpt-ekyc-terraform-state"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state_public_access_block" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "tf_state_folder_live" {
  bucket = aws_s3_bucket.tf_state.id
  key    = "live/"
  content = ""
}

resource "aws_s3_object" "tf_state_folder_dev" {
  bucket = aws_s3_bucket.tf_state.id
  key    = "dev/"
  content = ""
}

resource "aws_s3_bucket" "vnptekycupload" {
  bucket = "vnptekycupload"  # Must be globally unique

    tags = {
    name        = "vnptekycupload"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "vnptekycupload_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "vnptekycupload_public_access_block" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}