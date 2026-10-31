terraform {
  # The bucket name contains the account ID, so it is passed at init time
  # instead of being written here (keeps the code portable between accounts):
  #
  #   terraform init -backend-config="bucket=messagespring-tfstate-<account-id>-ap-southeast-7"
  #
  # The other settings can't come from variables (backends are configured
  # before variables exist), hence the literal region and alias.
  backend "s3" {
    key    = "envs/prod/terraform.tfstate"
    region = "ap-southeast-7"

    # Native S3 locking (a .tflock object next to the state); no DynamoDB table.
    use_lockfile = true

    # Encrypt with the state CMK from infra/bootstrap. `encrypt = true` on its
    # own would request SSE-S3 and bypass the bucket's KMS default.
    encrypt    = true
    kms_key_id = "alias/messagespring-tfstate"
  }
}
