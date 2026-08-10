variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "istio-baremetal-k8s"
}

variable "environment" {
  description = "The deployment environment."
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "Optional VPC ID override. If empty, fetched from VPC remote state."
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "Optional VPC CIDR override. If empty, fetched from VPC remote state."
  type        = string
  default     = ""
}
