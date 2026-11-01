locals {
  # role key => the exact `sub` claim allowed to assume it
  role_subjects = merge(
    {
      ecr-push   = "${local.sub_prefix}:ref:refs/heads/main"
      infra-plan = "${local.sub_prefix}:pull_request"
    },
    { for env in var.apply_environments : "infra-apply-${env}" => "${local.sub_prefix}:environment:${env}" },
  )
}

data "aws_iam_policy_document" "trust" {
  for_each = local.role_subjects

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Exact match, no wildcards: another repo, branch, fork or environment
    # gets a different `sub` and is refused.
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = [each.value]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = local.role_subjects

  name                 = "${var.name}-github-${each.key}"
  description          = "GitHub Actions (${each.value})"
  assume_role_policy   = data.aws_iam_policy_document.trust[each.key].json
  max_session_duration = 3600

  tags = var.tags
}

# ---------------------------------------------------------------- ecr-push

resource "aws_iam_role_policy" "ecr_push" {
  name   = "ecr-push"
  role   = aws_iam_role.this["ecr-push"].id
  policy = data.aws_iam_policy_document.ecr_push.json
}

# -------------------------------------------------------------- infra-plan

# Read everything (to refresh state), write nothing except the state lock file.
resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.this["infra-plan"].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "terraform-state"
  role   = aws_iam_role.this["infra-plan"].id
  policy = data.aws_iam_policy_document.plan_state.json
}

# ----------------------------------------------------------- infra-apply-*

# Applying this repo's Terraform creates IAM roles, so the apply role is effectively
# an administrator. It's guarded by where it can be used from: only a job running in
# the named GitHub Environment, which only `main` may deploy to (and prod needs a
# reviewer's approval).
resource "aws_iam_role_policy_attachment" "apply" {
  for_each = toset(var.apply_environments)

  role       = aws_iam_role.this["infra-apply-${each.key}"].name
  policy_arn = var.apply_policy_arn
}
