# GitHub Actions authenticates to AWS with short-lived OIDC tokens; there are no
# stored AWS keys. Each role trusts exactly one kind of workflow run, matched on
# the token's `sub` claim:
#
#   ecr-push              repo:<owner>/<repo>:ref:refs/heads/main    push images from main only
#   ecr-scan              repo:<owner>/<repo>:ref:refs/heads/main    pull images for the daily rescan
#   infra-plan            repo:<owner>/<repo>:pull_request           read-only plan on PRs
#   infra-apply-<env>     repo:<owner>/<repo>:environment:<env>      apply, behind a GitHub Environment
#
# None of these roles has Kubernetes access: CI changes Git, Argo CD changes the cluster.
#
#   oidc-provider.tf  the account's OIDC identity provider for GitHub
#   roles.tf          the roles and their trust policies
#   policies.tf       permission policies

data "aws_partition" "current" {}

locals {
  oidc_host = "token.actions.githubusercontent.com"

  sub_prefix = "repo:${var.github_repository}"
}
