variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "istio-k8s"
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"
}

# ---------------- Network ----------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per availability zone (EKS needs at least 2 AZs)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "EKS requires subnets in at least two availability zones."
  }
}

# ---------------- EKS ----------------

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.35" # standard support until 2027-03-27; older versions bill $0.60/h extended support
}

variable "cluster_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the node group (several similar types improve Spot availability)"
  type        = list(string)
  default     = ["t3.small", "t3a.small"]
}

variable "node_capacity_type" {
  description = "SPOT (up to ~70% cheaper, can be interrupted and replaced) or ON_DEMAND"
  type        = string
  default     = "SPOT"
}

variable "node_count" {
  description = "Fixed number of worker nodes"
  type        = number
  default     = 2
}

variable "node_disk_size" {
  description = "Root EBS volume size (GiB) per node"
  type        = number
  default     = 20
}

variable "admin_principal_arns" {
  description = "Extra IAM user/role ARNs to grant cluster-admin (the identity that creates the cluster is admin automatically)"
  type        = list(string)
  default     = []
}
