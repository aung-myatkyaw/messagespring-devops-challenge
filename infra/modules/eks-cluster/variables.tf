variable "name" {
  description = "Cluster name, also used as a prefix for its IAM roles (e.g. messagespring-prod)."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version of the control plane and nodes."
  type        = string
  default     = "1.36"
}

# ------------------------------------------------------------------ network

variable "vpc_id" {
  description = "VPC to create the cluster in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the nodes and pods (one per AZ)."
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "Subnets for the EKS control-plane ENIs; the network module's intra subnets (no internet route)."
  type        = list(string)
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint (admin office/VPN egress). Empty list: private endpoint only."
  type        = list(string)

  validation {
    condition     = !contains(var.endpoint_public_access_cidrs, "0.0.0.0/0")
    error_message = "Don't open the Kubernetes API to the whole internet; list specific admin CIDRs."
  }
}

# ------------------------------------------------------------------- access

variable "admin_principal_arns" {
  description = "IAM roles or users granted cluster-admin through access entries (e.g. the SSO admin role and a break-glass role). Never CI roles."
  type        = list(string)

  validation {
    condition     = length(var.admin_principal_arns) > 0
    error_message = "admin_principal_arns needs at least one principal; cluster creator admin is off, so the cluster would have no human admin."
  }

  validation {
    condition     = alltrue([for arn in var.admin_principal_arns : can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:(role|user)/", arn))])
    error_message = "admin_principal_arns must be IAM role or user ARNs (arn:aws:iam::<account>:role/... or :user/...)."
  }
}

# -------------------------------------------------------------------- nodes

variable "system_node_group" {
  description = "On-Demand managed node group for platform components (tainted CriticalAddonsOnly). Application nodes come from Karpenter. Terraform ignores later desired_size changes."
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
  })
}

variable "node_disk_size" {
  description = "Root volume size of each node in GiB (container images and logs)."
  type        = number
  default     = 30
}

# ------------------------------------------------------------ cluster misc

variable "addon_versions" {
  description = "Optional exact versions per EKS add-on name (e.g. { coredns = \"v1.13.1-eksbuild.1\" }). Unset add-ons use the latest version compatible with the cluster."
  type        = map(string)
  default     = {}
}

variable "cluster_log_retention_days" {
  description = "Retention of control-plane logs in CloudWatch Logs."
  type        = number
  default     = 30
}

variable "deletion_protection" {
  description = "Block cluster deletion through the EKS API. Turn off in throwaway environments."
  type        = bool
  default     = true
}

# ----------------------------------------------------- Pod Identity scoping

variable "external_secrets_parameter_arns" {
  description = "SSM Parameter Store ARNs External Secrets may read (wildcards allowed, e.g. arn:aws:ssm:<region>:<account>:parameter/<project>/<env>/*)."
  type        = list(string)
}

variable "external_secrets_kms_key_arns" {
  description = "Customer-managed KMS keys that encrypt those SecureString parameters (External Secrets gets kms:Decrypt on these only)."
  type        = list(string)

  # The community module falls back to kms:Decrypt on every key in every account
  # when this list is empty.
  validation {
    condition     = length(var.external_secrets_kms_key_arns) > 0
    error_message = "List at least one KMS key ARN; an empty list grants kms:Decrypt on all keys."
  }
}

variable "loki_bucket_arns" {
  description = "S3 buckets Loki stores chunks and ruler data in."
  type        = list(string)
}

variable "loki_kms_key_arn" {
  description = "KMS key that encrypts the Loki buckets."
  type        = string
}

variable "tags" {
  description = "Extra tags for every resource in the module."
  type        = map(string)
  default     = {}
}
