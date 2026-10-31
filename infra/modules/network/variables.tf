variable "name" {
  description = "Name prefix for the VPC and its resources (e.g. messagespring-prod)."
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block. Must be a /16; subnets are carved from it per AZ."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.cidr)) && endswith(var.cidr, "/16")
    error_message = "cidr must be a valid IPv4 /16 block."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3 (EKS needs at least two AZs)."
  }
}

variable "single_nat_gateway" {
  description = "true: one shared NAT gateway (cheaper, for non-prod). false: one NAT per AZ (no cross-AZ dependency, for prod)."
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Retention of VPC flow logs in CloudWatch Logs."
  type        = number
  default     = 30
}

variable "private_subnet_tags" {
  description = "Extra tags for the private (node) subnets, e.g. karpenter.sh/discovery so Karpenter launches nodes there."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Extra tags for every resource in the module."
  type        = map(string)
  default     = {}
}
