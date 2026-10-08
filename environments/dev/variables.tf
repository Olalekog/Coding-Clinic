variable "region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "name" {
  description = "Base name for the VPC and its resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment: dev, stage, uat, or prod."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to span."
  type        = number
}

variable "tags" {
  description = "Extra tags to apply to all resources."
  type        = map(string)
  default     = {}
}
