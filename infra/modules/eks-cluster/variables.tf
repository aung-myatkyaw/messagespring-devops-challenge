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

variable "admin_role_arns" {
  description = "IAM roles granted cluster-admin through access entries (e.g. the SSO admin role and a break-glass role). Never CI roles."
  type        = list(string)

  validation {
    condition     = alltrue([for arn in var.admin_role_arns : can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/", arn))])
    error_message = "admin_role_arns must be IAM role ARNs (arn:aws:iam::<account>:role/...)."
  }
}

# -------------------------------------------------------------------- nodes

variable "node_instance_types" {
  description = "Instance types for the managed node group (x86_64). More than one widens the Spot pool."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_min_size" {
  description = "Minimum number of nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes."
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Initial number of nodes. Terraform ignores later changes to it, so a cluster autoscaler can own it."
  type        = number
  default     = 2
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

variable "external_secrets_secret_arns" {
  description = "Secrets Manager ARNs (wildcards allowed, e.g. an environment prefix) External Secrets may read."
  type        = list(string)
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
