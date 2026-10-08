locals {
  name = "${var.name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "terraform-aws-vpc"
    }
  )

  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    min(var.az_count, length(data.aws_availability_zones.available.names))
  )

  # Public subnets take netnums from 0, private subnets from the midpoint of
  # the range, so the two tiers never collide as az_count grows.
  private_netnum_offset = pow(2, var.subnet_newbits - 1)

  public_subnets = {
    for idx, az in local.azs : az => cidrsubnet(var.vpc_cidr, var.subnet_newbits, idx)
  }

  private_subnets = {
    for idx, az in local.azs : az => cidrsubnet(var.vpc_cidr, var.subnet_newbits, idx + local.private_netnum_offset)
  }

  single_nat_gateway = coalesce(var.single_nat_gateway, var.environment == "dev")

  # AZs that get their own NAT gateway.
  nat_azs = !var.enable_nat_gateway ? [] : (
    local.single_nat_gateway ? slice(local.azs, 0, 1) : local.azs
  )
}

# Standard AZs only: Local Zones and Wavelength Zones can't host NAT gateways.
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  # Both are required for private DNS on the interface endpoints.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = local.name })

  lifecycle {
    precondition {
      condition     = length(local.azs) == var.az_count
      error_message = "az_count is ${var.az_count}, but this region only has ${length(data.aws_availability_zones.available.names)} available availability zones."
    }
  }
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(local.common_tags, {
    Name = "${local.name}-private-${each.key}"
    Tier = "private"
  })
}

# ---------------------------------------------------------------------------
# Internet gateway + public routing
# ---------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, { Name = "${local.name}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, { Name = "${local.name}-public" })
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# NAT gateway(s) + private routing
# ---------------------------------------------------------------------------

resource "aws_eip" "nat" {
  for_each = toset(local.nat_azs)

  domain = "vpc"

  tags = merge(local.common_tags, { Name = "${local.name}-nat-${each.key}" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = toset(local.nat_azs)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(local.common_tags, { Name = "${local.name}-nat-${each.key}" })

  depends_on = [aws_internet_gateway.this]
}

# One private route table per AZ regardless of NAT mode, so switching between
# a single and per-AZ NAT gateways only rewrites routes.
resource "aws_route_table" "private" {
  for_each = toset(local.azs)

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, { Name = "${local.name}-private-${each.key}" })
}

resource "aws_route" "private_nat_access" {
  for_each = var.enable_nat_gateway ? aws_route_table.private : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[local.single_nat_gateway ? local.azs[0] : each.key].id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
