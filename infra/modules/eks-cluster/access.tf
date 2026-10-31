# Kubernetes API access through EKS access entries: an IAM principal is mapped to an
# AWS-managed access policy, all in the EKS API (auditable in CloudTrail, no
# aws-auth ConfigMap to break).
#
# Only human admins (e.g. an SSO admin or break-glass role) get access.
# CI has no entry on purpose: it changes Git, and Argo CD changes the cluster.

locals {
  # Keyed by principal name (not list index), so reordering the list doesn't recreate entries.
  access_entries = {
    for arn in var.admin_principal_arns : basename(arn) => {
      principal_arn = arn
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}
