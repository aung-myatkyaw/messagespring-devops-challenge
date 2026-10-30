# One IAM role per controller, bound to exactly one namespace/service account
# through an EKS Pod Identity association. The Pod Identity agent (an add-on)
# hands the pod short-lived credentials; no OIDC provider or role annotations.
#
# The namespaces and service account names below must match the Helm values
# under k8s/platform/.
#
# external-dns has no AWS role: DNS is in Cloudflare, so it authenticates with a
# Cloudflare API token that External Secrets syncs from Secrets Manager.

locals {
  service_accounts = {
    aws_load_balancer_controller = { namespace = "kube-system", service_account = "aws-load-balancer-controller" }
    external_secrets             = { namespace = "external-secrets", service_account = "external-secrets" }
    loki                         = { namespace = "logging", service_account = "loki" }
  }
}

# The EBS CSI driver is an EKS add-on; its association is set on the add-on itself
# (addons.tf), so this role has none here.
module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.10.0"

  name = "${var.name}-ebs-csi"

  attach_aws_ebs_csi_policy = true

  tags = var.tags
}

module "aws_load_balancer_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.10.0"

  name = "${var.name}-aws-lbc"

  attach_aws_lb_controller_policy = true

  associations = {
    this = merge(local.service_accounts.aws_load_balancer_controller, { cluster_name = module.eks.cluster_name })
  }

  tags = var.tags
}

module "external_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.10.0"

  name = "${var.name}-external-secrets"

  # Read-only, and only the secrets under this environment's prefix.
  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = var.external_secrets_secret_arns
  external_secrets_create_permission    = false

  associations = {
    this = merge(local.service_accounts.external_secrets, { cluster_name = module.eks.cluster_name })
  }

  tags = var.tags
}

module "loki_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.10.0"

  name = "${var.name}-loki"

  attach_custom_policy    = true
  source_policy_documents = [data.aws_iam_policy_document.loki.json]

  associations = {
    this = merge(local.service_accounts.loki, { cluster_name = module.eks.cluster_name })
  }

  tags = var.tags
}
