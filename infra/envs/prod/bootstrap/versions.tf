terraform {
  # 1.11+ to match the other roots; < 2.0 blocks a future breaking major version.
  # Works for both Terraform and OpenTofu.
  required_version = ">= 1.11, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.71"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.3"
    }
  }
}
