output "certificate_arn" {
  description = "ARN of the issued ACM certificate."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "domain_name" {
  description = "Hostname the certificate covers (the Ingress host)."
  value       = var.domain_name
}

output "cloudflare_zone_id" {
  description = "ID of the Cloudflare zone (external-dns zone ID filter)."
  value       = data.cloudflare_zone.this.zone_id
}
