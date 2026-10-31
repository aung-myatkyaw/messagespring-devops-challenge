# Account-wide resources used by every environment:
#
#   ecr.tf          the image repository (one image, promoted dev → prod by tag)
#   github-oidc.tf  GitHub Actions OIDC provider and the CI roles
#
# Apply order: infra/bootstrap → this root → envs/dev → envs/prod. The first
# apply of this root is run by an administrator, because it creates the roles
# CI would otherwise use to apply it.

data "aws_caller_identity" "current" {}

# The state bucket and its key are created by infra/bootstrap. They're looked
# up by naming convention, so no account ID is written in the repo and this
# root doesn't read bootstrap's (local) state.
data "aws_s3_bucket" "state" {
  bucket = "${var.project}-tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"
}

data "aws_kms_alias" "state" {
  name = "alias/${var.project}-tfstate"
}
