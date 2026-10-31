module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name               = var.name
  kubernetes_version = var.kubernetes_version

  # Nodes in the private subnets; the control-plane ENIs in the intra subnets,
  # which have no route to the internet.
  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  # Nodes reach the API privately inside the VPC. The public endpoint exists only
  # for human admins and is limited to the CIDRs given (office/VPN egress).
  endpoint_private_access      = true
  endpoint_public_access       = length(var.endpoint_public_access_cidrs) > 0
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  # Access entries only (access.tf); the legacy aws-auth ConfigMap is not used.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = false

  # Envelope encryption of Kubernetes Secrets with a customer-managed KMS key
  # (created by the module, rotation on).
  encryption_config = {
    resources = ["secrets"]
  }

  # Control-plane logs to CloudWatch: who did what (audit), API errors (api), and
  # IAM-to-Kubernetes authentication (authenticator).
  enabled_log_types                      = ["api", "audit", "authenticator"]
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_days

  # Pod Identity replaces IRSA for every workload here, so no OIDC provider.
  enable_irsa = false

  # STANDARD: when standard support for a version ends, EKS upgrades the control
  # plane instead of silently moving to extended support ($0.60/h instead of $0.10/h).
  upgrade_policy = {
    support_type = "STANDARD"
  }

  deletion_protection = var.deletion_protection

  eks_managed_node_groups = local.node_groups

  # Karpenter's EC2NodeClass finds the node security group by this tag.
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.name
  }
  addons         = local.addons
  access_entries = local.access_entries

  tags = var.tags
}
