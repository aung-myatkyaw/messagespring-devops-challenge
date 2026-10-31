# dev: cheap and disposable. Compare with ../prod/terraform.tfvars.

environment = "dev"
region      = "ap-southeast-7"

# Network
vpc_cidr           = "10.10.0.0/16"
az_count           = 3
single_nat_gateway = true # one NAT instead of three; an AZ outage can take dev's egress down

# EKS
kubernetes_version           = "1.36"
endpoint_public_access_cidrs = ["203.0.113.10/32"] # placeholder (documentation range): your admin egress IP
cluster_log_retention_days   = 7
deletion_protection          = false

# Platform nodes (On-Demand). Application nodes come from Karpenter: Spot in dev
# (k8s/charts/karpenter-nodes). One system node: dev's platform isn't highly available.
system_node_group = {
  instance_types = ["t3.large"]
  min_size       = 1
  max_size       = 2
  desired_size   = 1
}

# Logging
loki_retention_days    = 7
alb_log_retention_days = 30
force_destroy          = true

# Secrets
kms_deletion_window_days = 7

# DNS (placeholders: an existing Cloudflare zone and a hostname in it)
cloudflare_zone_name = "example.com"
app_hostname         = "messagespring-dev.example.com"
