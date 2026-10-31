# Argo CD bootstrap for one environment. Applied once by a human admin after
# the cluster in ../ exists (docs/runbooks/cluster-bootstrap.md). It is a
# separate root because the Helm provider needs a running cluster to plan
# against, and because CI must never hold cluster credentials: CI plans and
# applies ../, never this folder.

data "aws_eks_cluster" "this" {
  name = "${var.project}-${var.environment}"
}

module "argocd" {
  source = "../../../modules/argocd-bootstrap"

  # The same values files the argo-cd Application uses, so when Argo CD takes
  # over its own release nothing changes.
  argocd_values = [
    file("${path.module}/../../../../k8s/platform/argo-cd/values.yaml"),
    file("${path.module}/../../../../k8s/platform/argo-cd/values-${var.environment}.yaml"),
  ]

  repo_url        = var.repo_url
  target_revision = var.target_revision
  root_path       = "k8s/argocd/envs/${var.environment}"
}
