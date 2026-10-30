# EKS cluster with one managed node group, wrapping the community EKS and
# EKS Pod Identity modules with our defaults.
#
#   cluster.tf       the cluster itself: endpoint, encryption, logs, upgrade policy
#   node-groups.tf   managed node group (AL2023, private subnets, IMDSv2 hop limit 1)
#   addons.tf        EKS managed add-ons (VPC CNI with network policy, CoreDNS, ...)
#   access.tf        who can use the Kubernetes API (access entries, no aws-auth)
#   pod-identity.tf  IAM roles for in-cluster controllers, bound to service accounts
#   iam.tf           custom IAM policy documents used by pod-identity.tf
#
# The cluster creator gets no Kubernetes permissions: humans come in through the
# admin roles in access.tf, and CI never talks to the cluster (Argo CD does).

data "aws_partition" "current" {}
