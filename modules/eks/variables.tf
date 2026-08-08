variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.28"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the cluster"
}

variable "cluster_role_arn" {
  type        = string
  description = "IAM role ARN for EKS cluster"
}

variable "node_role_arn" {
  type        = string
  description = "IAM role ARN for nodes"
}

variable "desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 2
}

variable "min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 5
}

variable "instance_types" {
  type        = list(string)
  description = "Instance types for worker nodes"
  default     = ["t3.medium"]
}
