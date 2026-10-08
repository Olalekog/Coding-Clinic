# terraform-aws-vpc

Multi-AZ VPC with a public and a private subnet in each availability zone, NAT
gateways for private egress, an S3 gateway endpoint, and ECR interface
endpoints.

## Usage

```hcl
provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source = "./terraform-aws-vpc"

  name        = "platform"
  environment = "prod" # dev | stage | uat | prod

  vpc_cidr = "10.0.0.0/16"
  az_count = 3
}
```

The module has no region input: it deploys into the region of the `aws`
provider it is given, and discovers that region's availability zones and
endpoint service names itself. To deploy to several regions, call it once per
provider alias.

## What the environment changes

| | dev | stage | uat | prod |
|---|---|---|---|---|
| NAT gateways | 1, shared | 1 per AZ | 1 per AZ | 1 per AZ |

Set `single_nat_gateway` explicitly to override. The environment also appears
in resource names (`<name>-<environment>-...`) and the `Environment` tag.

## Subnet layout

Subnets are sized by `subnet_newbits` (default 4, so a /16 VPC gives /20
subnets). Public subnets are numbered from the bottom of the VPC range and
private subnets from the midpoint:

| AZ | Public | Private |
|---|---|---|
| 1st | 10.0.0.0/20 | 10.0.128.0/20 |
| 2nd | 10.0.16.0/20 | 10.0.144.0/20 |
| 3rd | 10.0.32.0/20 | 10.0.160.0/20 |

## Inputs

| Name | Description | Default |
|---|---|---|
| `name` | Base name for resources | required |
| `environment` | `dev`, `stage`, `uat`, or `prod` | required |
| `vpc_cidr` | VPC IPv4 CIDR | `10.0.0.0/16` |
| `az_count` | Number of AZs to span (2-6) | `3` |
| `subnet_newbits` | Bits added to the VPC prefix per subnet (4-12) | `4` |
| `enable_nat_gateway` | Create NAT gateway(s) | `true` |
| `single_nat_gateway` | Share one NAT gateway across AZs | `true` in dev, else `false` |
| `enable_s3_endpoint` | Create the S3 gateway endpoint | `true` |
| `enable_ecr_endpoints` | Create the `ecr.api` and `ecr.dkr` interface endpoints | `true` |
| `tags` | Extra tags for all resources | `{}` |

Outputs are described in [outputs.tf](outputs.tf).

## Testing

```sh
terraform init
terraform test
```

The tests plan against a mocked provider, so they need no AWS credentials
(Terraform 1.7 or later).
