# VPC for an EKS cluster, wrapping the community VPC module with our defaults.
#
# Three subnet tiers per AZ:
#   public  /24  internet-facing ALBs and NAT gateways only
#   private /20  EKS nodes and pods (VPC CNI gives each pod a VPC IP, hence the size)
#   intra   /24  EKS control-plane ENIs; no route to the internet at all
#
#   vpc.tf        the VPC, subnets, NAT gateways and flow logs (community module)
#   endpoints.tf  VPC endpoints

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_region" "current" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # From a /16: private 10.x.0.0/20, 10.x.16.0/20, 10.x.32.0/20;
  # public 10.x.48-50.0/24; intra 10.x.52-54.0/24.
  private_subnets = [for i, _ in local.azs : cidrsubnet(var.cidr, 4, i)]
  public_subnets  = [for i, _ in local.azs : cidrsubnet(var.cidr, 8, i + 48)]
  intra_subnets   = [for i, _ in local.azs : cidrsubnet(var.cidr, 8, i + 52)]
}
