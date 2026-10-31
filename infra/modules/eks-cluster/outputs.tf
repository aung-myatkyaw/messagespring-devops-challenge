output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint (used by the Argo CD bootstrap layer)."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA certificate of the API endpoint."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_version" {
  description = "Kubernetes version of the control plane."
  value       = module.eks.cluster_version
}

output "node_security_group_id" {
  description = "Security group shared by the nodes."
  value       = module.eks.node_security_group_id
}

output "secrets_kms_key_arn" {
  description = "KMS key used for envelope encryption of Kubernetes Secrets."
  value       = module.eks.kms_key_arn
}

output "control_plane_log_group_name" {
  description = "CloudWatch log group with the control-plane logs."
  value       = module.eks.cloudwatch_log_group_name
}

output "pod_identity_role_arns" {
  description = "IAM role per in-cluster controller, bound via Pod Identity."
  value = {
    aws_ebs_csi_driver           = module.ebs_csi_pod_identity.iam_role_arn
    aws_load_balancer_controller = module.aws_load_balancer_controller_pod_identity.iam_role_arn
    external_secrets             = module.external_secrets_pod_identity.iam_role_arn
    karpenter                    = module.karpenter.iam_role_arn
    loki                         = module.loki_pod_identity.iam_role_arn
  }
}

output "karpenter_queue_name" {
  description = "SQS queue with interruption events (Karpenter Helm value settings.interruptionQueue)."
  value       = module.karpenter.queue_name
}

output "karpenter_node_role_name" {
  description = "IAM role for nodes Karpenter launches (EC2NodeClass spec.role)."
  value       = module.karpenter.node_iam_role_name
}
