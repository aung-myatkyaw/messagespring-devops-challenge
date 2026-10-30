# Remote state backend for every other Terraform root in this repo.
#
# Roots use the S3 backend with native locking (use_lockfile = true, S3
# conditional writes), so no DynamoDB lock table is needed.
#
#   kms.tf  customer-managed key that encrypts the state
#   s3.tf   the state bucket and its hardening

data "aws_caller_identity" "current" {}

locals {
  # Account ID + region keep the globally unique bucket name collision-free.
  bucket_name = "${var.project}-tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"
}
