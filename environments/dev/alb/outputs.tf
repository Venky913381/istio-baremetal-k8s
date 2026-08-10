output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

output "alb_id" {
  description = "ID of the ALB"
  value       = module.alb.alb_id
}

output "target_group_arn" {
  description = "ARN of the ALB Target Group"
  value       = module.alb.target_group_arn
}

output "listener_arn" {
  description = "ARN of the ALB listener"
  value       = module.alb.listener_arn
}
