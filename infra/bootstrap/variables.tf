variable "project" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "messagespring"
}

variable "region" {
  description = "AWS region for the state bucket and its KMS key."
  type        = string
}

variable "noncurrent_version_retention_days" {
  description = "How long to keep previous versions of state files (to recover from a bad apply or corruption)."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Extra tags added to every resource (e.g. Owner, CostCenter)."
  type        = map(string)
  default     = {}
}
