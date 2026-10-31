variable "namespace" {
  description = "Namespace Argo CD is installed in."
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "argo-cd chart version for the first install. Later upgrades go through the argo-cd Application in Git."
  type        = string
  default     = "10.11.6"
}

variable "argocd_apps_chart_version" {
  description = "argocd-apps chart version (creates the root AppProject and Application)."
  type        = string
  default     = "2.0.7"
}

variable "argocd_values" {
  description = "argo-cd chart values as YAML strings, later ones winning. Pass the same files the argo-cd Application uses, so the handover to Argo CD changes nothing."
  type        = list(string)
}

variable "repo_url" {
  description = "HTTPS URL of the Git repository Argo CD tracks."
  type        = string

  validation {
    condition     = can(regex("^https://", var.repo_url))
    error_message = "repo_url must be an https:// URL."
  }
}

variable "target_revision" {
  description = "Branch, tag or commit the root Application tracks."
  type        = string
  default     = "main"
}

variable "root_path" {
  description = "Directory in the repository holding this environment's child Applications (e.g. k8s/argocd/envs/dev)."
  type        = string

  validation {
    condition     = !startswith(var.root_path, "/") && !endswith(var.root_path, "/")
    error_message = "root_path is relative to the repository root, without leading or trailing slashes."
  }
}
