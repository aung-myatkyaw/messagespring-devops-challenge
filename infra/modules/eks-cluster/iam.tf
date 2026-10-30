# Loki stores chunks and ruler data in S3. It needs object read/write/delete
# (the compactor deletes expired chunks) on its own buckets only, plus the KMS key
# that encrypts them.
data "aws_iam_policy_document" "loki" {
  statement {
    sid       = "ListLokiBuckets"
    actions   = ["s3:ListBucket"]
    resources = var.loki_bucket_arns
  }

  statement {
    sid       = "ReadWriteLokiObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [for arn in var.loki_bucket_arns : "${arn}/*"]
  }

  statement {
    sid       = "UseLokiBucketKey"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [var.loki_kms_key_arn]
  }
}
