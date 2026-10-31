module "eks" {
  source = "../../modules/eks-cluster"

  name               = local.name
  kubernetes_version = var.kubernetes_version

  vpc_id                   = module.network.vpc_id
  private_subnet_ids       = module.network.private_subnet_ids
  control_plane_subnet_ids = module.network.intra_subnet_ids

  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  admin_principal_arns         = local.admin_principal_arns

  # Platform nodes only; application nodes come from Karpenter.
  system_node_group = var.system_node_group

  cluster_log_retention_days = var.cluster_log_retention_days
  deletion_protection        = var.deletion_protection

  # parameter_path starts with "/", which the ARN doesn't repeat:
  # arn:aws:ssm:<region>:<account>:parameter/messagespring/dev/*
  external_secrets_parameter_arns = [
    "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.parameter_path}/*",
  ]
  external_secrets_kms_key_arns = [aws_kms_key.secrets.arn]

  loki_bucket_arns = module.log_storage.loki_bucket_arns
  loki_kms_key_arn = module.log_storage.loki_kms_key_arn

  tags = local.tags
}
