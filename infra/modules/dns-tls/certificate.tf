resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  # A replacement certificate is issued before the old one is removed, so the
  # ALB listener is never left without one.
  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# One CNAME per hostname on the certificate. ACM returns names and values with
# a trailing dot; Cloudflare stores them without, so trim to avoid a perpetual diff.
resource "cloudflare_dns_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name    = trimsuffix(dvo.resource_record_name, ".")
      type    = dvo.resource_record_type
      content = trimsuffix(dvo.resource_record_value, ".")
    }
  }

  zone_id = data.cloudflare_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  ttl     = 300

  # DNS only: a proxied CNAME would answer with Cloudflare's IPs instead of the
  # record ACM looks for, and validation would never succeed.
  proxied = false

  # The zone is shared with other records; say who owns this one.
  comment = "ACM validation for ${var.domain_name}, managed by Terraform"
}

# Makes `apply` wait until the certificate is issued, so it's usable as soon as
# the root finishes.
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in cloudflare_dns_record.validation : record.name]
}
