# GitHub Actions authenticates to AWS with short-lived OIDC tokens; there are no
# stored AWS keys. Each role trusts exactly one kind of workflow run, matched on
# the token's `sub` claim:
#
#   ecr-push              <prefix>:ref:refs/heads/main    push images from main only
#   ecr-scan              <prefix>:ref:refs/heads/main    pull images for the daily rescan
#   infra-plan            <prefix>:pull_request           read-only plan on PRs
#   infra-apply-<env>     <prefix>:environment:<env>      apply, behind a GitHub Environment
#
# <prefix> is GitHub's immutable subject, repo:<owner>@<owner-id>/<repo>@<repo-id>.
# The numeric IDs never change, so if the repository is renamed or deleted, a new
# repository that takes over the name gets a different subject and can't assume
# these roles. GitHub uses this format for repositories created since mid-2026;
# older ones opt in under Settings > Actions > OIDC.
#
# None of these roles has Kubernetes access: CI changes Git, Argo CD changes the cluster.
#
#   oidc-provider.tf  the account's OIDC identity provider for GitHub
#   roles.tf          the roles and their trust policies
#   policies.tf       permission policies

data "aws_partition" "current" {}

locals {
  oidc_host = "token.actions.githubusercontent.com"

  github_owner = split("/", var.github_repository)[0]
  github_repo  = split("/", var.github_repository)[1]

  sub_prefix = "repo:${local.github_owner}@${var.github_owner_id}/${local.github_repo}@${var.github_repository_id}"
}
