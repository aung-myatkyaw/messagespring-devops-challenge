# Access is audited with CloudTrail at the account level rather than S3 server
# access logs, which would need yet another bucket for each of these.
resource "aws_s3_bucket" "this" {
  for_each = local.buckets

  bucket = local.bucket_names[each.key]

  # Lets `terraform destroy` empty a throwaway environment's buckets.
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    object_ownership = "BucketOwnerEnforced" # disables ACLs; access is IAM-only
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = each.value.kms ? "aws:kms" : "AES256"
      kms_master_key_id = each.value.kms ? aws_kms_key.logs.arn : null
    }
    bucket_key_enabled = each.value.kms # fewer KMS requests, lower cost
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id

  dynamic "rule" {
    for_each = each.value.expiration_days != null ? [each.value.expiration_days] : []

    content {
      id     = "expire-objects"
      status = "Enabled"

      filter {}

      expiration {
        days = rule.value
      }
    }
  }

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
