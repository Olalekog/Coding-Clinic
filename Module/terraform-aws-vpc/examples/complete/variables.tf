variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-1"
}

variable "name" {
  description = "Base name for the VPC and its resources."
  type        = string
  default     = "platform"
}

variable "environment" {
  description = "Deployment environment: dev, stage, uat, or prod."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to span."
  type        = number
  default     = 3
}

variable "tags" {
  description = "Extra tags to apply to all resources."
  type        = map(string)
  default = {
    Project = "coding-clinic"
  }
}
