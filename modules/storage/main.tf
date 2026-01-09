resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-logs-${var.account_id}-${var.region}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-logs"
    }
  )
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
