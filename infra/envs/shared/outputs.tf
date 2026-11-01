# Values to copy into GitHub repository/environment variables after apply.

output "ecr_repository_url" {
  description = "Image repository (GitHub variable ECR_REPOSITORY; image.repository in the Helm values)."
  value       = module.ecr.repository_url
}

output "ecr_push_role_arn" {
  description = "Role for the image build workflow (GitHub variable AWS_ROLE_ARN)."
  value       = module.github_oidc.ecr_push_role_arn
}

output "ecr_scan_role_arn" {
  description = "Pull-only role for the daily image rescan (GitHub variable ECR_SCAN_ROLE_ARN)."
  value       = module.github_oidc.ecr_scan_role_arn
}

output "infra_plan_role_arn" {
  description = "Read-only role for terraform plan on pull requests."
  value       = module.github_oidc.infra_plan_role_arn
}

output "infra_apply_role_arns" {
  description = "Apply role per GitHub Environment (environment variable of each)."
  value       = module.github_oidc.infra_apply_role_arns
}

output "state_bucket_name" {
  description = "State bucket name (GitHub variable TF_STATE_BUCKET, passed to init as -backend-config)."
  value       = data.aws_s3_bucket.state.bucket
}
