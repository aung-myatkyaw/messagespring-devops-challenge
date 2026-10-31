# One small managed node group, "system", for the components that must exist
# before Karpenter can add capacity, and that shouldn't sit on Spot: Karpenter
# itself, Argo CD, the controllers, CoreDNS, Loki and Grafana.
#
# Always On-Demand, labelled role=system and tainted
# CriticalAddonsOnly=true:NoSchedule, so application pods can't land here and
# starve the platform. Platform pods select it with nodeSelector role=system
# plus the matching toleration (set in their Helm values). DaemonSets that run
# on every node (VPC CNI, kube-proxy, Pod Identity agent, EBS CSI node, Alloy)
# tolerate all taints.
#
# Application capacity comes from Karpenter (karpenter.tf): NodePools in
# k8s/platform/karpenter decide On-Demand vs Spot per environment.

locals {
  node_groups = {
    system = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.system_node_group.instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.system_node_group.min_size
      max_size     = var.system_node_group.max_size
      desired_size = var.system_node_group.desired_size

      labels = { role = "system" }
      taints = {
        critical_addons_only = { key = "CriticalAddonsOnly", value = "true", effect = "NO_SCHEDULE" }
      }

      # Encrypted gp3 root volume (the AMI default is a smaller gp2 volume).
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.node_disk_size
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # IMDSv2 only, hop limit 1: pods can't reach the instance metadata service,
      # so they can't borrow the node's IAM role. Workloads get their own role via
      # Pod Identity instead. (This is why the LB controller is given its VPC ID
      # and region explicitly; it can't discover them from IMDS.) Karpenter's
      # EC2NodeClass sets the same for its nodes.
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      # Replace one node at a time during AMI or version upgrades; PodDisruptionBudgets
      # keep the platform available while nodes drain.
      update_config = {
        max_unavailable = 1
      }

      # EKS replaces nodes that stay unhealthy (NotReady, kubelet or disk failures).
      node_repair_config = {
        enabled = true
      }
    }
  }
}
