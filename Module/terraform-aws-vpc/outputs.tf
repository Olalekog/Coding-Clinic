output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "Availability zones the subnets span. Subnet and route table ID lists are in this order."
  value       = local.azs
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, one per AZ."
  value       = [for az in local.azs : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, one per AZ."
  value       = [for az in local.azs : aws_subnet.private[az].id]
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets, keyed by AZ."
  value       = local.public_subnets
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets, keyed by AZ."
  value       = local.private_subnets
}

output "internet_gateway_id" {
  description = "ID of the internet gateway."
  value       = aws_internet_gateway.this.id
}

output "public_route_table_id" {
  description = "ID of the shared public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables, one per AZ."
  value       = [for az in local.azs : aws_route_table.private[az].id]
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateway(s), keyed by AZ."
  value       = { for az, nat in aws_nat_gateway.this : az => nat.id }
}

output "nat_gateway_public_ips" {
  description = "Public (Elastic) IPs of the NAT gateway(s), keyed by AZ."
  value       = { for az, eip in aws_eip.nat : az => eip.public_ip }
}

output "s3_endpoint_id" {
  description = "ID of the S3 gateway endpoint, if created."
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "ecr_endpoint_ids" {
  description = "IDs of the ECR interface endpoints, keyed by service (ecr.api, ecr.dkr)."
  value       = { for service, endpoint in aws_vpc_endpoint.interface : service => endpoint.id }
}

output "vpc_endpoint_security_group_id" {
  description = "ID of the security group attached to the interface endpoints, if created."
  value       = try(aws_security_group.vpc_endpoints[0].id, null)
}
