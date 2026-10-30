resource "aws_ecr_repository" "this" {
  name = var.name

  # A tag can never be pushed twice, so a commit-SHA tag always means the same
  # image digest. What was tested in dev is exactly what runs in prod.
  image_tag_mutability = "IMMUTABLE"

  # Basic scanning on every push (free). CI also runs Trivy before pushing and
  # fails on HIGH/CRITICAL; this catches the image as it was actually stored.
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  force_delete = var.force_delete

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = local.lifecycle_policy
}
