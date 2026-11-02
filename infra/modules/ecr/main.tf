# Container registry for the application image. Shared by all environments:
# CI builds an image once, tags it with the Git commit SHA, and dev and prod run
# that same image. Promotion changes which tag an environment uses, never the image.
#
#   kms.tf          customer-managed key for image encryption
#   repository.tf   the repository, scanning and lifecycle policy

locals {
  # One rule only: keep the newest N images (tagged or not), expire the rest.
  # No separate "expire untagged" rule: CI pushes one plain manifest per tag
  # (provenance and SBOM attestations off), so nothing untagged builds up; and if
  # attestations are turned on, they're untagged manifests inside a tagged index
  # that such a rule would break. Keep N larger than prod's rollback window.
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the newest ${var.keep_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.keep_image_count
        }
        action = { type = "expire" }
      },
    ]
  })
}
