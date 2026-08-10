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

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.28"
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

variable "cluster_role_arn" {
  description = "Optional IAM Role ARN for EKS Cluster. If empty, fetched from IAM remote state."
  type        = string
  default     = ""
}

variable "node_role_arn" {
  description = "Optional IAM Role ARN for EKS Nodes. If empty, fetched from IAM remote state."
  type        = string
  default     = ""
}

variable "desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "instance_types" {
  description = "Instance types for node group."
  type        = list(string)
  default     = ["t3.medium"]
}
