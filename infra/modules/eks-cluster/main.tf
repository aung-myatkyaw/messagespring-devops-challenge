# EKS cluster with a system node group and Karpenter for application nodes,
# wrapping the community EKS (+ its Karpenter submodule) and EKS Pod Identity
# modules with our defaults.
#
#   cluster.tf       the cluster itself: endpoint, encryption, logs, upgrade policy
#   node-groups.tf   "system" managed node group: On-Demand, tainted, for the platform
#   karpenter.tf     Karpenter's IAM roles and Spot interruption queue
#   addons.tf        EKS managed add-ons (VPC CNI with network policy, CoreDNS, ...)
#   access.tf        who can use the Kubernetes API (access entries, no aws-auth)
#   pod-identity.tf  IAM roles for in-cluster controllers, bound to service accounts
#   iam.tf           custom IAM policy documents used by pod-identity.tf
#
# The cluster creator gets no Kubernetes permissions: humans come in through the
# admin roles in access.tf, and CI never talks to the cluster (Argo CD does).

data "aws_partition" "current" {}
