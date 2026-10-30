# Logs can contain user data, so the Loki buckets use a customer-managed key:
# reading them needs both S3 and KMS permissions, and every decrypt is in CloudTrail.
# Only Loki's Pod Identity role is granted use of the key (in the eks-cluster module).
resource "aws_kms_key" "logs" {
  description             = "Encrypts Loki log storage for ${var.name}"
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_deletion_window_days

  tags = var.tags
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.name}-logs"
  target_key_id = aws_kms_key.logs.key_id
}
