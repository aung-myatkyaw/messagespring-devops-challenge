variable "project" {
  description = "Project name; with environment, gives the cluster name."
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
  description = "AWS region of the cluster (must match the backend region)."
  type        = string
}

variable "repo_url" {
  description = "HTTPS URL of this Git repository, tracked by Argo CD."
  type        = string
}

variable "target_revision" {
  description = "Branch Argo CD tracks. Both environments track main; they differ by folder and values file, not by branch."
  type        = string
  default     = "main"
}
