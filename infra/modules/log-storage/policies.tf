data "aws_iam_policy_document" "bucket" {
  for_each = local.buckets

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.this[each.key].arn,
      "${aws_s3_bucket.this[each.key].arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # ALB log delivery: only load balancers in this account and region, and only
  # under this account's path.
  dynamic "statement" {
    for_each = each.key == "alb-logs" ? [1] : []

    content {
      sid       = "AllowAlbLogDelivery"
      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.this[each.key].arn}/${local.alb_log_prefix}/AWSLogs/${local.account_id}/*"]

      principals {
        type        = "Service"
        identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
      }

      condition {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = ["arn:${data.aws_partition.current.partition}:elasticloadbalancing:${data.aws_region.current.region}:${local.account_id}:loadbalancer/*"]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id
  policy = data.aws_iam_policy_document.bucket[each.key].json

  depends_on = [aws_s3_bucket_public_access_block.this]
}
