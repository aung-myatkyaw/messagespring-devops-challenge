# Installs Argo CD once and gives it one root Application (app-of-apps) that
# points at this repository. Everything else in the cluster, including later
# Argo CD upgrades, then comes from Git:
#
#   Terraform ──installs──> Argo CD ──syncs──> root Application
#                                                └─> child Applications in Git
#                                                    (platform add-ons, the web app,
#                                                     and Argo CD itself)
#
# Only a human admin runs this (see docs/runbooks/cluster-bootstrap.md); CI has
# no access to the cluster.

locals {
  in_cluster = "https://kubernetes.default.svc"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = var.namespace
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  values     = var.argocd_values

  # Fail the apply (and roll back) if the pods don't become ready, instead of
  # leaving a half-installed release behind.
  atomic  = true
  timeout = 600

  lifecycle {
    # After the first install, the argo-cd Application in Git manages this
    # release with the same values files. Ignoring changes here stops a later
    # `terraform apply` from rolling Argo CD back to the bootstrap version.
    ignore_changes = all
  }
}

# The argocd-apps chart creates Argo CD's own CRD objects (AppProject,
# Application) as an ordinary Helm release. With the kubernetes provider's
# kubernetes_manifest, the plan would fail because those CRDs don't exist yet.
resource "helm_release" "root_app" {
  name      = "argocd-root"
  namespace = var.namespace

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version

  values = [yamlencode({
    # The root app's project may only read this repository and only create
    # Argo CD Applications and AppProjects in the Argo CD namespace. Real
    # workloads get their permissions from the projects defined in Git.
    projects = {
      root = {
        namespace   = var.namespace
        description = "App-of-apps root: creates Applications and AppProjects only"
        sourceRepos = [var.repo_url]
        destinations = [{
          server    = local.in_cluster
          namespace = var.namespace
        }]
        clusterResourceWhitelist = []
        namespaceResourceWhitelist = [
          { group = "argoproj.io", kind = "Application" },
          { group = "argoproj.io", kind = "AppProject" },
        ]
      }
    }

    applications = {
      root = {
        namespace = var.namespace
        project   = "root"
        source = {
          repoURL        = var.repo_url
          targetRevision = var.target_revision
          path           = var.root_path
        }
        destination = {
          server    = local.in_cluster
          namespace = var.namespace
        }
        # prune: removing a child Application's file from Git deletes it.
        # selfHeal: manual edits to child Applications are reverted.
        # No resources-finalizer on purpose: deleting the root by mistake
        # leaves the child Applications (and their workloads) running.
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
        }
      }
    }
  })]

  depends_on = [helm_release.argocd]
}
