# EKS managed add-ons: AWS installs and patches them, versions are matched to the
# cluster version. Without a pin in var.addon_versions, the module picks the latest
# version compatible with the cluster at plan time, and the plan shows any change.
#
# Everything else (LB controller, external-dns, ...) is installed by Argo CD from Git.

locals {
  addons = {
    # Installed before the nodes join, so nodes come up with networking and the
    # Pod Identity agent already in place.
    vpc-cni = {
      before_compute = true
      addon_version  = lookup(var.addon_versions, "vpc-cni", null)
      # Enforce Kubernetes NetworkPolicy objects (eBPF, no extra CNI needed).
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
      })
    }

    eks-pod-identity-agent = {
      before_compute = true
      addon_version  = lookup(var.addon_versions, "eks-pod-identity-agent", null)
    }

    kube-proxy = {
      addon_version = lookup(var.addon_versions, "kube-proxy", null)
    }

    coredns = {
      addon_version = lookup(var.addon_versions, "coredns", null)
    }

    # EBS volumes for PersistentVolumeClaims (Loki's write-ahead log).
    aws-ebs-csi-driver = {
      addon_version = lookup(var.addon_versions, "aws-ebs-csi-driver", null)
      pod_identity_association = [{
        role_arn        = module.ebs_csi_pod_identity.iam_role_arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
  }
}
