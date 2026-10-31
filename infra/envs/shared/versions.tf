terraform {
  # 1.11+ for write-only arguments; < 2.0 blocks a future breaking major version.
  # Works for both Terraform and OpenTofu. CI pins the exact Terraform version.
  required_version = ">= 1.11, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.71"
    }
  }
}
