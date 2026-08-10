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

variable "subnet_ids" {
  description = "Optional Subnet IDs override. If empty, fetched from VPC remote state."
  type        = list(string)
  default     = []
}

variable "security_group_id" {
  description = "Optional Security Group ID override. If empty, fetched from Security Groups remote state."
  type        = string
  default     = ""
}
