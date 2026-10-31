variable "project" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "messagespring"
}

variable "region" {
  description = "AWS region (must match the backend region and infra/bootstrap)."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository (owner/repo) whose workflows may assume the CI roles."
  type        = string
}

variable "tags" {
  description = "Extra tags added to every resource (e.g. Owner, CostCenter)."
  type        = map(string)
  default     = {}
}
