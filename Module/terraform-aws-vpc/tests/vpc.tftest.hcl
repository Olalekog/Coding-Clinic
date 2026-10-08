# Plan-only tests against a mocked provider: no AWS credentials or resources.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    }
  }
}

variables {
  name = "platform"
}

run "dev_shares_one_nat_gateway" {
  command = plan

  variables {
    environment = "dev"
  }

  assert {
    condition     = length(aws_subnet.public) == 3 && length(aws_subnet.private) == 3
    error_message = "Expected one public and one private subnet per AZ."
  }

  assert {
    condition     = aws_subnet.public["eu-west-1a"].cidr_block == "10.0.0.0/20" && aws_subnet.private["eu-west-1a"].cidr_block == "10.0.128.0/20"
    error_message = "Public subnets should start at the bottom of the VPC range and private subnets at the midpoint."
  }

  assert {
    condition     = keys(aws_nat_gateway.this) == ["eu-west-1a"]
    error_message = "dev should default to a single NAT gateway in the first AZ."
  }

  assert {
    condition     = length(aws_route.private_nat_access) == 3
    error_message = "Every private route table needs a default route to the NAT gateway."
  }

  assert {
    condition     = length(aws_vpc_endpoint.s3) == 1 && sort(keys(aws_vpc_endpoint.interface)) == tolist(["ecr.api", "ecr.dkr"])
    error_message = "Expected the S3 gateway endpoint and both ECR interface endpoints."
  }
}

run "prod_gets_a_nat_gateway_per_az" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "prod should default to one NAT gateway per AZ."
  }
}

run "uat_gets_a_nat_gateway_per_az" {
  command = plan

  variables {
    environment = "uat"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "uat should default to one NAT gateway per AZ."
  }
}

run "single_nat_gateway_overrides_the_environment_default" {
  command = plan

  variables {
    environment        = "prod"
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "single_nat_gateway = true should win over the prod default."
  }
}

run "nat_and_endpoints_can_be_disabled" {
  command = plan

  variables {
    environment          = "stage"
    enable_nat_gateway   = false
    enable_s3_endpoint   = false
    enable_ecr_endpoints = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_route.private_nat_access) == 0
    error_message = "No NAT gateways or NAT routes should be planned."
  }

  assert {
    condition     = length(aws_vpc_endpoint.s3) == 0 && length(aws_vpc_endpoint.interface) == 0 && length(aws_security_group.vpc_endpoints) == 0
    error_message = "No VPC endpoints or endpoint security group should be planned."
  }
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "staging"
  }

  expect_failures = [var.environment]
}

run "rejects_more_azs_than_the_region_has" {
  command = plan

  variables {
    environment = "dev"
    az_count    = 4
  }

  expect_failures = [aws_vpc.this]
}
