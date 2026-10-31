# The ALB uses this certificate (found by the Ingress host), and external-dns
# points the hostname at the ALB in the same Cloudflare zone.
module "dns_tls" {
  source = "../../modules/dns-tls"

  zone_name   = var.cloudflare_zone_name
  domain_name = var.app_hostname
}
