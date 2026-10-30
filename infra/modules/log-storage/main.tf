# S3 storage for logs, one set per environment:
#
#   loki-chunks  Loki log data. Loki's compactor enforces retention; the bucket
#                lifecycle is a safety net a few days longer than that.
#   loki-ruler   Loki ruler state (alerting/recording rules). Small, kept.
#   alb-logs     ALB access logs, written by the Elastic Load Balancing service.
#
#   kms.tf      customer-managed key for the Loki buckets
#   s3.tf       the buckets and the hardening every bucket gets
#   policies.tf bucket policies (TLS only, plus ALB log delivery)
#
# The ALB logs bucket uses SSE-S3: it's the only encryption ALB log delivery supports.
#
# No versioning on purpose: these buckets hold append-only, re-creatable telemetry,
# and versioning would keep every chunk Loki's compactor deletes (cost, and logs
# outliving their retention).

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # Account ID + region keep the globally unique names collision-free (max 63 chars).
  buckets = {
    loki-chunks = {
      kms             = true
      expiration_days = var.loki_retention_days + 7
    }
    loki-ruler = {
      kms             = true
      expiration_days = null
    }
    alb-logs = {
      kms             = false
      expiration_days = var.alb_log_retention_days
    }
  }

  bucket_names = {
    for key, _ in local.buckets : key => "${var.name}-${key}-${local.account_id}-${data.aws_region.current.region}"
  }

  # ALB access logs land under <prefix>/AWSLogs/<account-id>/ in the bucket.
  alb_log_prefix = "alb"
}
