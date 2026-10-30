provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        Project   = var.project
        Component = "terraform-state"
        ManagedBy = "terraform"
      },
      var.tags,
    )
  }
}
