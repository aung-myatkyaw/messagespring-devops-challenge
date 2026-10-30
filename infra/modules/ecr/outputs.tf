output "repository_name" {
  description = "Name of the repository."
  value       = aws_ecr_repository.this.name
}

output "repository_arn" {
  description = "ARN of the repository (for the CI push role)."
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "Registry URL to push and pull (<account>.dkr.ecr.<region>.amazonaws.com/<name>)."
  value       = aws_ecr_repository.this.repository_url
}
