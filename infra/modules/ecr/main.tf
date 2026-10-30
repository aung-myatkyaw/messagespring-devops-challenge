# Container registry for the application image. Shared by all environments:
# CI builds an image once, tags it with the Git commit SHA, and dev and prod run
# that same image. Promotion changes which tag an environment uses, never the image.
#
#   kms.tf          customer-managed key for image encryption
#   repository.tf   the repository, scanning and lifecycle policy

locals {
  # One rule only: keep the newest N images (tagged or not), expire the rest.
  # No separate "expire untagged" rule: buildx pushes provenance attestations as
  # untagged manifests inside a tagged image index, and expiring them would break
  # the index. Keep N larger than the number of releases prod could roll back to.
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
