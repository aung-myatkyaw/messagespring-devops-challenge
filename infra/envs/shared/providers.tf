# Credentials come from the environment: AWS_PROFILE (SSO) on a laptop, OIDC
# role credentials in CI. Never a `profile` or keys here.
provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        Project       = var.project
        Environment   = "shared"
        ManagedBy     = "terraform"
        TerraformRoot = "infra/envs/shared"
      },
      var.tags,
    )
  }
}
