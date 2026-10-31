# EKS managed add-ons: AWS installs and patches them, versions are matched to the
# cluster version. Without a pin in var.addon_versions, the module picks the latest
# version compatible with the cluster at plan time, and the plan shows any change.
#
# Everything else (LB controller, external-dns, ...) is installed by Argo CD from Git.

locals {
  # Schedule onto the system node group (node-groups.tf).
  system_placement = {
    nodeSelector = { role = "system" }
    tolerations  = [{ key = "CriticalAddonsOnly", operator = "Exists" }]
  }

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

    # DNS runs on the On-Demand system nodes, not on nodes Karpenter may
    # consolidate or that Spot may reclaim.
    coredns = {
      addon_version        = lookup(var.addon_versions, "coredns", null)
      configuration_values = jsonencode(local.system_placement)
    }

    # EBS volumes for PersistentVolumeClaims (Loki's write-ahead log).
    aws-ebs-csi-driver = {
      addon_version = lookup(var.addon_versions, "aws-ebs-csi-driver", null)
      # The controller goes on the system nodes; the node DaemonSet runs
      # everywhere (it tolerates all taints by default).
      configuration_values = jsonencode({
        controller = local.system_placement
      })
      pod_identity_association = [{
        role_arn        = module.ebs_csi_pod_identity.iam_role_arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
  }
}
