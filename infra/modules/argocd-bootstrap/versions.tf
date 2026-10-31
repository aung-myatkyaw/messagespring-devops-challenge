terraform {
  # 1.11+ to match every other root and module in this repo; < 2.0 blocks a
  # future breaking major version. Works for both Terraform and OpenTofu.
  required_version = ">= 1.11, < 2.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.3"
    }
  }
}
