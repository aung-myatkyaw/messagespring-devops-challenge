# Secrets the cluster needs, stored as SSM Parameter Store SecureStrings and
# synced into Kubernetes Secrets by External Secrets (Pod Identity, read-only,
# this environment's path only). Their values never pass through Git or
# Terraform state.
#
# Parameter Store rather than Secrets Manager: Standard-tier parameters are free
# (Secrets Manager is $0.40 per secret per month), and nothing here needs what
# Secrets Manager adds (managed rotation, cross-region replication, resource
# policies for other accounts). Database credentials that rotate would go there.

resource "aws_kms_key" "secrets" {
  description             = "Encrypts SecureString parameters for ${local.name}"
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_deletion_window_days
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# ------------------------------------------------------------ Grafana admin

# Ephemeral: generated during apply and never saved in plan or state.
ephemeral "random_password" "grafana_admin" {
  length  = 32
  special = false
}

# Write-only (value_wo): sent to AWS, never stored in state. It is only written
# when the version changes, so bump it to rotate the password. The admin user
# name isn't secret; it's set in the Grafana values.
resource "aws_ssm_parameter" "grafana_admin_password" {
  name        = "${local.parameter_path}/grafana/admin-password"
  description = "Grafana admin password (synced to the logging namespace by External Secrets)."
  type        = "SecureString"
  tier        = "Standard"
  key_id      = aws_kms_key.secrets.arn

  value_wo         = ephemeral.random_password.grafana_admin.result
  value_wo_version = 1
}

# ------------------------------------------------- Cloudflare token (external-dns)

# A parameter can't be created empty, so Terraform writes a placeholder and an
# administrator overwrites it with a zone-scoped Cloudflare token (Zone:Read +
# DNS:Edit) after apply (docs/runbooks/cluster-bootstrap.md). The value is
# write-only, so Terraform never reads the real token back or reverts it.
resource "aws_ssm_parameter" "cloudflare_api_token" {
  name        = "${local.parameter_path}/external-dns/cloudflare-api-token"
  description = "Cloudflare API token for external-dns (value set by hand, not by Terraform)."
  type        = "SecureString"
  tier        = "Standard"
  key_id      = aws_kms_key.secrets.arn

  value_wo         = "set-by-hand"
  value_wo_version = 1
}
