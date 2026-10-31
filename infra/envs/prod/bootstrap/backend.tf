terraform {
  # Same bucket as ../ (passed at init), separate state file:
  #
  #   terraform init -backend-config="bucket=messagespring-tfstate-<account-id>-ap-southeast-7"
  backend "s3" {
    key    = "envs/prod/bootstrap/terraform.tfstate"
    region = "ap-southeast-7"

    use_lockfile = true
    encrypt      = true
    kms_key_id   = "alias/messagespring-tfstate"
  }
}
