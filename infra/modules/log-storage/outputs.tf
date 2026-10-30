output "loki_chunks_bucket_name" {
  description = "Bucket for Loki chunks (Loki Helm values: storage bucketNames.chunks)."
  value       = aws_s3_bucket.this["loki-chunks"].bucket
}

output "loki_ruler_bucket_name" {
  description = "Bucket for Loki ruler data (Loki Helm values: storage bucketNames.ruler)."
  value       = aws_s3_bucket.this["loki-ruler"].bucket
}

output "loki_bucket_arns" {
  description = "ARNs of the Loki buckets (for Loki's Pod Identity role)."
  value       = [aws_s3_bucket.this["loki-chunks"].arn, aws_s3_bucket.this["loki-ruler"].arn]
}

output "loki_kms_key_arn" {
  description = "KMS key that encrypts the Loki buckets."
  value       = aws_kms_key.logs.arn
}

output "alb_logs_bucket_name" {
  description = "Bucket for ALB access logs (Ingress annotation access_logs.s3.bucket)."
  value       = aws_s3_bucket.this["alb-logs"].bucket
}

output "alb_logs_prefix" {
  description = "Prefix for ALB access logs (Ingress annotation access_logs.s3.prefix)."
  value       = local.alb_log_prefix
}
