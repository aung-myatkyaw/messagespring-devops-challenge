# Roles GitHub Actions assumes through OIDC (no stored AWS keys): push images
# from main, plan on pull requests, apply per protected GitHub Environment.
module "github_oidc" {
  source = "../../modules/github-oidc"

  name              = var.project
  github_repository = var.github_repository

  ecr_repository_arns = [module.ecr.repository_arn]

  state_bucket_arn  = data.aws_s3_bucket.state.arn
  state_kms_key_arn = data.aws_kms_alias.state.target_key_arn
}
