# One repository for all environments: CI builds an image once, and the same
# immutable tag (the commit SHA) is deployed to dev and then promoted to prod.
module "ecr" {
  source = "../../modules/ecr"

  name = "${var.project}/web"
}
