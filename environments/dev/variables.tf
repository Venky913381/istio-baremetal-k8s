variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "istio-baremetal-lab"
}

variable "environment" {
  description = "The deployment environment."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1" # N. Virginia
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "The domain name for the Route53 hosted zone."
  type        = string
  default     = "example-dev.com"
}