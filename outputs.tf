# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = try(module.vpc.vpc_id, null)
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = try(module.vpc.vpc_cidr, null)
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = try(module.vpc.public_subnet_ids, [])
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = try(module.vpc.private_subnet_ids, [])
}

# EKS Outputs
output "eks_cluster_id" {
  description = "ID of the EKS cluster"
  value       = try(module.eks.cluster_id, null)
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = try(module.eks.cluster_endpoint, null)
}

output "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = try(module.eks.cluster_security_group_id, null)
}

# IAM Outputs
output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = try(module.iam.eks_node_role_arn, null)
}

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = try(module.iam.eks_cluster_role_arn, null)
}
