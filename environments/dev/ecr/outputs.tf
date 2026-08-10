output "ecr_repository_url" {
  description = "URL of the ECR repository for the application."
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository."
  value       = module.ecr.repository_arn
}
