# State contains resource attributes that can be sensitive, so it is encrypted with
# a customer-managed key. It keeps the default key policy, which delegates access to
# IAM: the CI plan/apply roles get it through their policies (infra/modules/github-oidc),
# administrators through their own permissions.
resource "aws_kms_key" "state" {
  description             = "Encrypts Terraform state for ${var.project}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "state" {
  name          = "alias/${var.project}-tfstate"
  target_key_id = aws_kms_key.state.key_id
}
