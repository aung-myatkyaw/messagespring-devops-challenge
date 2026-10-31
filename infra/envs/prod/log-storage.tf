module "log_storage" {
  source = "../../modules/log-storage"

  name = local.name

  # Must match Loki's retention in k8s/platform/loki; the bucket lifecycle is a
  # safety net a week behind it.
  loki_retention_days    = var.loki_retention_days
  alb_log_retention_days = var.alb_log_retention_days

  kms_deletion_window_days = var.kms_deletion_window_days
  force_destroy            = var.force_destroy
}
