variable "name" {
  description = "Base name for the VPC and its resources. The environment is appended, e.g. \"platform\" becomes \"platform-dev\"."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,31}$", var.name))
    error_message = "name must be 1-32 characters of lowercase letters, numbers, and hyphens, and must not start with a hyphen."
  }
}

variable "environment" {
  description = "Deployment environment. Used in names and tags, and sets the NAT gateway default (see single_nat_gateway)."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "uat", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, uat, prod."
  }
}

variable "tags" {
  description = "Extra tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "az_count" {
  description = "Number of availability zones to span. The first N standard AZs of the provider's region are used, with one public and one private subnet in each."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6 && floor(var.az_count) == var.az_count
    error_message = "az_count must be a whole number between 2 and 6."
  }
}

variable "subnet_newbits" {
  description = <<-EOT
    Bits added to the VPC prefix to size each subnet (a /16 VPC with 4 newbits
    gives /20 subnets). Public subnets are carved from the lower half of the
    VPC range and private subnets from the upper half, so changing az_count
    later never renumbers existing subnets.
  EOT
  type        = number
  default     = 4

  validation {
    condition     = var.subnet_newbits >= 4 && var.subnet_newbits <= 12 && floor(var.subnet_newbits) == var.subnet_newbits
    error_message = "subnet_newbits must be a whole number between 4 and 12."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateway(s) so private subnets get outbound internet access."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = <<-EOT
    If true, all private subnets share one NAT gateway (cheaper, but a single
    AZ failure takes out private egress). If false, each AZ gets its own.
    Defaults to true in dev and false in every other environment.
  EOT
  type        = bool
  default     = null
}

variable "enable_s3_endpoint" {
  description = "Whether to create an S3 gateway endpoint attached to the public and private route tables."
  type        = bool
  default     = true
}

variable "enable_ecr_endpoints" {
  description = <<-EOT
    Whether to create ECR interface endpoints (ecr.api and ecr.dkr) in the
    private subnets. Image layers are served from S3, so pulling images
    without NAT also needs enable_s3_endpoint.
  EOT
  type        = bool
  default     = true
}
