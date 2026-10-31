module "network" {
  source = "../../modules/network"

  name               = local.name
  cidr               = var.vpc_cidr
  az_count           = var.az_count
  single_nat_gateway = var.single_nat_gateway

  # Karpenter's EC2NodeClass launches nodes in subnets with this tag.
  private_subnet_tags = { "karpenter.sh/discovery" = local.name }
}
