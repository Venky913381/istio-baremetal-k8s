output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_id" {
  description = "ID of the ECS service"
  value       = module.ecs.service_id
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "task_definition_arn" {
  description = "ARN of the ECS Task Definition"
  value       = module.ecs.task_definition_arn
}
