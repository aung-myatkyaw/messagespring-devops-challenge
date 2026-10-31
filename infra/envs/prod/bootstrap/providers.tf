# Credentials come from the environment (AWS_PROFILE), like the parent root.
# This layer creates no AWS resources; AWS is only used to find the cluster
# and to get a Kubernetes token.
provider "aws" {
  region = var.region
}

# Talks to the cluster's API endpoint, which is reachable only from the admin
# CIDRs in ../terraform.tfvars. The token comes from `aws eks get-token` at run
# time, so it is short-lived and never stored in state. The caller needs an EKS
# access entry (one of the cluster admins).
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.this.name, "--region", var.region]
    }
  }
}
