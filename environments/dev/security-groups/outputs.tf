output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = module.security_groups.alb_security_group_id
}

output "eks_security_group_id" {
  description = "Security group ID for EKS"
  value       = module.security_groups.eks_security_group_id
}

output "database_security_group_id" {
  description = "Security group ID for databases"
  value       = module.security_groups.database_security_group_id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS"
  value       = module.security_groups.ecs_security_group_id
}
