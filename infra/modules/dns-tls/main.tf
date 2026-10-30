# TLS certificate for the application's hostname, issued by ACM and validated
# through DNS in an existing Cloudflare zone (the zone itself, i.e. the domain,
# is a prerequisite and not managed here).
#
# The AWS Load Balancer Controller finds this certificate by the Ingress host
# (no ARN in the manifests), and external-dns creates the host's record in the
# same Cloudflare zone. ACM renews the certificate automatically while the
# validation record exists.
#
#   certificate.tf  ACM certificate, Cloudflare validation records, wait for issuance

data "cloudflare_zone" "this" {
  filter = {
    name = var.zone_name
  }
}
