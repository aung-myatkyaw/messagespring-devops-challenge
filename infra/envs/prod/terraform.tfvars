# prod: highly available and protected. Compare with ../dev/terraform.tfvars.

environment = "prod"
region      = "ap-southeast-7"

# Network
vpc_cidr           = "10.20.0.0/16"
az_count           = 3
single_nat_gateway = false # one NAT per AZ, so an AZ outage doesn't cut egress for the others

# EKS
kubernetes_version           = "1.36"
endpoint_public_access_cidrs = ["203.0.113.10/32"] # placeholder (documentation range): your admin egress IP
cluster_log_retention_days   = 90
deletion_protection          = true

# Platform nodes (On-Demand), two AZs. Application nodes come from Karpenter:
# On-Demand in prod (k8s/platform/karpenter).
system_node_group = {
  instance_types = ["m7i.large"]
  min_size       = 2
  max_size       = 3
  desired_size   = 2
}

# Logging
loki_retention_days    = 30
alb_log_retention_days = 90
force_destroy          = false

# Secrets
kms_deletion_window_days = 30

# DNS (placeholders: an existing Cloudflare zone and a hostname in it)
cloudflare_zone_name = "example.com"
app_hostname         = "messagespring.example.com"
