# One per account. AWS validates GitHub's token signing certificate against its
# own trusted CAs, so no thumbprint is pinned here.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://${local.oidc_host}"
  client_id_list = ["sts.amazonaws.com"]

  tags = var.tags
}
