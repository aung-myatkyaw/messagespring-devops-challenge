output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC identity provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "ecr_push_role_arn" {
  description = "Role for the image build workflow (GitHub variable AWS_ROLE_ARN)."
  value       = aws_iam_role.this["ecr-push"].arn
}

output "infra_plan_role_arn" {
  description = "Read-only role for terraform plan on pull requests."
  value       = aws_iam_role.this["infra-plan"].arn
}

output "infra_apply_role_arns" {
  description = "Apply role per GitHub Environment."
  value       = { for env in var.apply_environments : env => aws_iam_role.this["infra-apply-${env}"].arn }
}
