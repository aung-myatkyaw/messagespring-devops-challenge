# Values the Argo CD bootstrap layer and the platform Helm values need.

output "region" {
  description = "AWS region of the environment."
  value       = var.region
}

output "cluster_name" {
  description = "EKS cluster name (bootstrap layer; aws eks update-kubeconfig)."
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "VPC ID (AWS Load Balancer Controller value vpcId)."
  value       = module.network.vpc_id
}

output "public_subnet_cidrs" {
  description = "Subnets the ALB connects to pods from (app NetworkPolicy ingress rule)."
  value       = module.network.public_subnet_cidrs
}

output "nat_public_ips" {
  description = "Egress IPs of the environment (for third-party allow-lists)."
  value       = module.network.nat_public_ips
}

output "karpenter_queue_name" {
  description = "Karpenter interruption queue (Karpenter Helm values)."
  value       = module.eks.karpenter_queue_name
}

output "karpenter_node_role_name" {
  description = "IAM role for Karpenter nodes (EC2NodeClass spec.role)."
  value       = module.eks.karpenter_node_role_name
}

output "pod_identity_role_arns" {
  description = "IAM role per in-cluster controller, bound via Pod Identity."
  value       = module.eks.pod_identity_role_arns
}

output "loki_chunks_bucket_name" {
  description = "Loki chunks bucket (Loki Helm values)."
  value       = module.log_storage.loki_chunks_bucket_name
}

output "loki_ruler_bucket_name" {
  description = "Loki ruler bucket (Loki Helm values)."
  value       = module.log_storage.loki_ruler_bucket_name
}

output "alb_logs_bucket_name" {
  description = "ALB access-log bucket (Ingress annotation)."
  value       = module.log_storage.alb_logs_bucket_name
}

output "alb_logs_prefix" {
  description = "ALB access-log prefix (Ingress annotation)."
  value       = module.log_storage.alb_logs_prefix
}

output "app_hostname" {
  description = "Public hostname of the application (Ingress host)."
  value       = module.dns_tls.domain_name
}

output "certificate_arn" {
  description = "ACM certificate for the hostname (discovered by the LB controller; for reference)."
  value       = module.dns_tls.certificate_arn
}

output "cloudflare_zone_id" {
  description = "Cloudflare zone ID (external-dns zone ID filter)."
  value       = module.dns_tls.cloudflare_zone_id
}

output "grafana_admin_password_parameter" {
  description = "Parameter with the Grafana admin password (ExternalSecret remote key)."
  value       = aws_ssm_parameter.grafana_admin_password.name
}

output "cloudflare_api_token_parameter" {
  description = "Parameter to put the external-dns Cloudflare token in (ExternalSecret remote key)."
  value       = aws_ssm_parameter.cloudflare_api_token.name
}
