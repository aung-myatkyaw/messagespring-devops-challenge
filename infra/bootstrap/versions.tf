terraform {
  # 1.11+ for write-only arguments; < 2.0 blocks a future breaking major version.
  # Works for both Terraform and OpenTofu. CI pins the exact Terraform version.
  required_version = ">= 1.11, < 2.0"

  # No backend block: this root keeps LOCAL state on purpose. It creates the S3
  # bucket that every other root stores its state in, so it can't use that bucket
  # itself. It is applied once by an administrator; the local state file is
  # git-ignored and only describes this bucket and its key.

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.71"
    }
  }
}
