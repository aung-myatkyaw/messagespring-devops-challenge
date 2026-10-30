variable "name" {
  description = "Name prefix for the buckets and key (e.g. messagespring-prod)."
  type        = string

  # <name>-loki-chunks-<12-digit account>-<region> must fit S3's 63-character limit.
  validation {
    condition     = can(regex("^[a-z0-9-]{1,20}$", var.name))
    error_message = "name must be 1-20 lowercase letters, digits or hyphens (S3 bucket name limits)."
  }
}

variable "loki_retention_days" {
  description = "Log retention Loki's compactor enforces. Must match the Loki Helm values; the chunks bucket expires objects 7 days later as a safety net."
  type        = number
  default     = 30
}

variable "alb_log_retention_days" {
  description = "Days to keep ALB access logs."
  type        = number
  default     = 90
}

variable "kms_deletion_window_days" {
  description = "Waiting period before the KMS key is deleted after a destroy (7-30)."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_days >= 7 && var.kms_deletion_window_days <= 30
    error_message = "kms_deletion_window_days must be between 7 and 30."
  }
}

variable "force_destroy" {
  description = "Allow destroying non-empty buckets. Only for throwaway environments."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags for every resource in the module."
  type        = map(string)
  default     = {}
}
