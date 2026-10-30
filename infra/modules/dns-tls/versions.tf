terraform {
  # 1.11+ for write-only arguments; < 2.0 blocks a future breaking major version.
  # Works for both Terraform and OpenTofu. CI pins the exact Terraform version.
  required_version = ">= 1.11, < 2.0"

  # Same constraints as every root in this repo: these modules are only called by
  # our own roots, so one consistent range is simpler than a looser module minimum,
  # and it keeps a breaking provider major from slipping in through a module.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.71"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28"
    }
  }
}
