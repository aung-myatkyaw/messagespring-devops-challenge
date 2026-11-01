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

variable "github_owner_id" {
  description = "Numeric ID of the repository owner: gh api repos/<owner>/<repo> --jq .owner.id"
  type        = number
}

variable "github_repository_id" {
  description = "Numeric ID of the repository: gh api repos/<owner>/<repo> --jq .id"
  type        = number
}

variable "tags" {
  description = "Extra tags added to every resource (e.g. Owner, CostCenter)."
  type        = map(string)
  default     = {}
}
