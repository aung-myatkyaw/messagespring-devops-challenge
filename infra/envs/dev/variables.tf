# Values that differ between dev and prod have no default on purpose: they are
# all set in terraform.tfvars, so comparing the two tfvars files shows the
# whole difference between the environments.

variable "project" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "messagespring"
}

variable "environment" {
  description = "Environment name (dev or prod)."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "region" {
  description = "AWS region (must match the backend region)."
  type        = string
}

variable "tags" {
  description = "Extra tags added to every resource (e.g. Owner, CostCenter)."
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------ network

variable "vpc_cidr" {
  description = "VPC CIDR (/16). Different per environment so the VPCs could be peered later."
  type        = string
}

variable "az_count" {
  description = "Number of availability zones for subnets and nodes."
  type        = number
}

variable "single_nat_gateway" {
  description = "One shared NAT gateway (cheaper) instead of one per AZ (survives an AZ outage)."
  type        = bool
}

# ---------------------------------------------------------------------- EKS

variable "kubernetes_version" {
  description = "Kubernetes minor version. Upgrade dev first, then prod."
  type        = string
}

variable "endpoint_public_access_cidrs" {
  description = "Admin egress CIDRs allowed to reach the public Kubernetes API endpoint. Empty: private only."
  type        = list(string)
}

variable "admin_sso_permission_set" {
  description = "IAM Identity Center permission set whose role gets cluster-admin."
  type        = string
  default     = "AdministratorAccess"
}

variable "extra_admin_role_arns" {
  description = "Other IAM roles that get cluster-admin (e.g. a break-glass role). Never CI roles."
  type        = list(string)
  default     = []
}

variable "system_node_group" {
  description = "On-Demand managed node group for platform components (Karpenter, Argo CD, controllers, Loki)."
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
  })
}

variable "cluster_log_retention_days" {
  description = "Retention of control-plane logs in CloudWatch Logs."
  type        = number
}

variable "deletion_protection" {
  description = "Block deleting the cluster through the EKS API."
  type        = bool
}

# ------------------------------------------------------------------ logging

variable "loki_retention_days" {
  description = "Loki log retention (must match the Loki Helm values)."
  type        = number
}

variable "alb_log_retention_days" {
  description = "How long ALB access logs are kept in S3."
  type        = number
}

variable "force_destroy" {
  description = "Allow destroying log buckets that still contain objects. Only for throwaway environments."
  type        = bool
}

# ------------------------------------------------------------------ secrets

variable "kms_deletion_window_days" {
  description = "Waiting period before a deleted KMS key is gone (7-30 days)."
  type        = number
}

# ---------------------------------------------------------------------- DNS

variable "cloudflare_zone_name" {
  description = "Existing Cloudflare zone (the domain)."
  type        = string
}

variable "app_hostname" {
  description = "Public hostname of the application, inside the Cloudflare zone."
  type        = string
}
