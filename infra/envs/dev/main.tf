# One environment (dev or prod; the roots differ only in backend.tf's key and
# terraform.tfvars):
#
#   network.tf      VPC, subnets, NAT, flow logs
#   eks.tf          EKS cluster, node group, add-ons, Pod Identity roles
#   log-storage.tf  S3 buckets for Loki and ALB access logs
#   dns.tf          ACM certificate validated in Cloudflare
#   secrets.tf      SecureString parameters read by External Secrets
#
# Argo CD is installed afterwards by the human-run layer in ./bootstrap; from
# then on, everything inside the cluster comes from Git.

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

# Cluster admins: the IAM Identity Center role of the given permission set in
# this account, looked up so no account-specific ARN is written in the repo.
data "aws_iam_roles" "sso_admin" {
  name_regex  = "^AWSReservedSSO_${var.admin_sso_permission_set}_[0-9a-f]+$"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"

  lifecycle {
    postcondition {
      condition     = length(self.arns) == 1
      error_message = "Expected exactly one IAM Identity Center role for permission set ${var.admin_sso_permission_set} in this account."
    }
  }
}

locals {
  name = "${var.project}-${var.environment}"

  # Applied to every AWS resource through the provider's default_tags, and
  # passed explicitly to the EKS module: default_tags don't reach the EC2
  # instances and volumes the node group's Auto Scaling group launches, so the
  # launch template needs them for cost allocation.
  tags = merge(
    {
      Project       = var.project
      Environment   = var.environment
      ManagedBy     = "terraform"
      TerraformRoot = "infra/envs/${var.environment}"
    },
    var.tags,
  )

  admin_role_arns = concat(tolist(data.aws_iam_roles.sso_admin.arns), var.extra_admin_role_arns)

  # Every secret of this environment is a parameter under this path; External
  # Secrets may read only these.
  parameter_path = "/${var.project}/${var.environment}"
}
