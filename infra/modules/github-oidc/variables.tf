variable "name" {
  description = "Name prefix for the IAM roles (e.g. messagespring)."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the roles, as owner/repo."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "github_repository must look like owner/repo."
  }
}

variable "apply_environments" {
  description = "GitHub Environments that run terraform apply; one role each (infra-apply-<env>)."
  type        = list(string)
  default     = ["shared", "dev", "prod"]
}

variable "apply_policy_arn" {
  description = "Managed policy for the apply roles. Applying creates IAM roles, so this is administrator-level in practice."
  type        = string
  default     = "arn:aws:iam::aws:policy/AdministratorAccess"
}

variable "ecr_repository_arns" {
  description = "ECR repositories the ecr-push role may push to and the ecr-scan role may pull from."
  type        = list(string)
}

variable "state_bucket_arn" {
  description = "Terraform state bucket (from infra/bootstrap)."
  type        = string
}

variable "state_kms_key_arn" {
  description = "KMS key that encrypts the state (from infra/bootstrap)."
  type        = string
}

variable "tags" {
  description = "Extra tags for every resource in the module."
  type        = map(string)
  default     = {}
}
