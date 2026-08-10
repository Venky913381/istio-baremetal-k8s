output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = module.iam.eks_node_role_arn
}

output "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = module.iam.eks_cluster_role_name
}

output "eks_node_role_name" {
  description = "Name of the EKS node IAM role"
  value       = module.iam.eks_node_role_name
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  value       = module.iam.ecs_task_execution_role_arn
}
