# S3 bucket for DSpace asset store
resource "aws_s3_bucket" "dspace_asset_store" {
  bucket        = var.dspace_asset_store_bucket_name
  force_destroy = var.s3_bucket_force_destroy
  tags          = local.tags
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "dspace_asset_store" {
  bucket = aws_s3_bucket.dspace_asset_store.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "dspace_asset_store" {
  bucket = aws_s3_bucket.dspace_asset_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "dspace_asset_store" {
  bucket = aws_s3_bucket.dspace_asset_store.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket for DSpace statistics exports
resource "aws_s3_bucket" "statistics_exports" {
  bucket        = "${var.organization}-${var.project_name}-statistics-exports"
  force_destroy = var.s3_bucket_force_destroy

  tags = merge(local.tags, {
    Name     = "${var.organization}-${var.project_name}-statistics-exports"
    Purpose  = "DSpace Statistics Exports"
    DataType = "Statistics"
  })
}

resource "aws_s3_bucket_versioning" "statistics_exports" {
  bucket = aws_s3_bucket.statistics_exports.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "statistics_exports" {
  bucket = aws_s3_bucket.statistics_exports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "statistics_exports" {
  bucket = aws_s3_bucket.statistics_exports.id

  rule {
    id     = "statistics_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "statistics_exports" {
  bucket = aws_s3_bucket.statistics_exports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy for statistics exports
resource "aws_s3_bucket_policy" "statistics_exports" {
  bucket = aws_s3_bucket.statistics_exports.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-backend-ecsTaskRole"
        }
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.statistics_exports.arn,
          "${aws_s3_bucket.statistics_exports.arn}/*"
        ]
      }
    ]
  })
}