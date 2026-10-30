output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = module.vpc.vpc_cidr_block
}

output "azs" {
  description = "Availability zones the subnets are spread across."
  value       = module.vpc.azs
}

output "private_subnet_ids" {
  description = "Private subnets for EKS nodes and pods."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnets for internet-facing load balancers."
  value       = module.vpc.public_subnets
}

output "intra_subnet_ids" {
  description = "Isolated subnets (no internet route) for EKS control-plane ENIs."
  value       = module.vpc.intra_subnets
}

output "public_subnet_cidrs" {
  description = "CIDRs of the public subnets; the ALB connects to pods from here (used in NetworkPolicies)."
  value       = local.public_subnets
}

output "nat_public_ips" {
  description = "Egress IPs of the NAT gateways (for allow-listing by third parties)."
  value       = module.vpc.nat_public_ips
}
