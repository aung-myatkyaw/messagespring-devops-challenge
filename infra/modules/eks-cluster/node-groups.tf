locals {
  node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

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
      # and region explicitly; it can't discover them from IMDS.)
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      # Replace one node at a time during AMI or version upgrades; PodDisruptionBudgets
      # keep the app available while nodes drain.
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
