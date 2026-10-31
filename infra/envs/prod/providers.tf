# Credentials come from the environment: AWS_PROFILE (SSO) on a laptop, OIDC
# role credentials in CI. Never a `profile` or keys here.
provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}

# Reads CLOUDFLARE_API_TOKEN from the environment (a token scoped to one zone).
# Cloudflare has no OIDC federation for GitHub, so in CI it's a secret.
provider "cloudflare" {}
