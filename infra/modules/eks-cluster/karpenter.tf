# AWS side of Karpenter. Karpenter launches EC2 instances directly for pending
# pods (picking instance types and On-Demand/Spot from its NodePools), and
# removes or replaces them when they're empty or underused (consolidation).
#
# Created here:
#   - controller IAM role, bound to kube-system/karpenter through Pod Identity
#   - node IAM role + EC2_LINUX access entry, so its nodes can join the cluster
#   - SQS queue + EventBridge rules for Spot interruption warnings, rebalance
#     recommendations, scheduled maintenance and instance state changes, so
#     Karpenter drains a node before AWS reclaims it
#
# The controller itself (Helm chart) and its NodePool/EC2NodeClass objects are
# installed by Argo CD from k8s/platform/karpenter. It runs on the system node
# group, never on nodes it manages. The EC2NodeClass finds subnets and the node
# security group by the tag karpenter.sh/discovery=<cluster name>.

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.29.0"

  cluster_name = module.eks.cluster_name

  # Pod Identity, same as every other controller (must match the Helm values).
  create_pod_identity_association = true
  namespace                       = local.service_accounts.karpenter.namespace
  service_account                 = local.service_accounts.karpenter.service_account

  # A fixed name, so the EC2NodeClass in Git can refer to it (spec.role).
  node_iam_role_name            = "${var.name}-karpenter-node"
  node_iam_role_use_name_prefix = false

  queue_name = "${var.name}-karpenter"

  tags = var.tags
}
