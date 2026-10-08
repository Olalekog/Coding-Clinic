locals {
  interface_endpoint_services = var.enable_ecr_endpoints ? toset(["ecr.api", "ecr.dkr"]) : toset([])
}

# Service names are looked up rather than built from the region string so the
# module also works in partitions with a different prefix (e.g. aws-cn).

# ---------------------------------------------------------------------------
# S3 gateway endpoint
# ---------------------------------------------------------------------------

data "aws_vpc_endpoint_service" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  service      = "s3"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = data.aws_vpc_endpoint_service.s3[0].service_name
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    [for az in local.azs : aws_route_table.private[az].id]
  )

  tags = merge(local.common_tags, { Name = "${local.name}-s3" })
}

# ---------------------------------------------------------------------------
# ECR interface endpoints
# ---------------------------------------------------------------------------

data "aws_vpc_endpoint_service" "interface" {
  for_each = local.interface_endpoint_services

  service      = each.key
  service_type = "Interface"
}

resource "aws_security_group" "vpc_endpoints" {
  count = length(local.interface_endpoint_services) > 0 ? 1 : 0

  name_prefix = "${local.name}-vpce-"
  description = "HTTPS from within the VPC to interface VPC endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-vpce" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoint_services

  vpc_id              = aws_vpc.this.id
  service_name        = data.aws_vpc_endpoint_service.interface[each.key].service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for az in local.azs : aws_subnet.private[az].id]
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, { Name = "${local.name}-${replace(each.key, ".", "-")}" })
}
