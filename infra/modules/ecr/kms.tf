# ECR uses KMS grants for its own encrypt/decrypt calls, so pushing and pulling
# need only ECR permissions, not KMS ones.
resource "aws_kms_key" "ecr" {
  description             = "Encrypts container images in ${var.name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = var.tags
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/${replace(var.name, "/", "-")}-ecr"
  target_key_id = aws_kms_key.ecr.key_id
}
