# Gateway endpoint: S3 traffic from private subnets (Loki chunks, ECR image layers)
# stays on the AWS network instead of going through NAT. It is free, whereas NAT
# charges per GB processed. (ALB access logs are delivered by the ELB service and
# never pass through the VPC.)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = merge(var.tags, { Name = "${var.name}-s3" })
}
