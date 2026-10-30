output "state_bucket_name" {
  description = "S3 bucket that stores the state of every other root."
  value       = aws_s3_bucket.state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the state bucket (for CI role policies)."
  value       = aws_s3_bucket.state.arn
}

output "state_kms_key_arn" {
  description = "KMS key that encrypts the state (for CI role policies)."
  value       = aws_kms_key.state.arn
}
