output "argocd_namespace" {
  description = "Namespace Argo CD runs in."
  value       = module.argocd.namespace
}

output "argocd_ui" {
  description = "How to reach the Argo CD UI (no Ingress: it isn't exposed outside the cluster)."
  value       = "kubectl -n ${module.argocd.namespace} port-forward svc/argocd-server 8080:443, then open https://localhost:8080"
}

output "root_application" {
  description = "Root Application; watch it with: kubectl -n argocd get applications"
  value       = module.argocd.root_application
}
