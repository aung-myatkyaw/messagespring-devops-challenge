output "namespace" {
  description = "Namespace Argo CD runs in."
  value       = helm_release.argocd.namespace
}

output "argocd_chart_version" {
  description = "argo-cd chart version installed by the bootstrap (Argo CD may have upgraded itself since)."
  value       = helm_release.argocd.version
}

output "root_application" {
  description = "Name of the root Application."
  value       = "root"
}
