module "vpc" {
  source = "../../Module/terraform-aws-vpc"

  name        = var.name
  environment = var.environment

  vpc_cidr = var.vpc_cidr
  az_count = var.az_count

  tags = var.tags
}
