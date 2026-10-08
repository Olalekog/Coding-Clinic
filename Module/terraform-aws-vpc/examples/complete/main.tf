# The module deploys into whatever region its provider is configured for.
provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../.."

  name        = var.name
  environment = var.environment

  vpc_cidr = var.vpc_cidr
  az_count = var.az_count

  tags = var.tags
}
