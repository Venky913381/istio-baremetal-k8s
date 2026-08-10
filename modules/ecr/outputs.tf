output "repository_url" {
  description = "URL of the created ECR repository."
  value       = aws_ecr_repository.main.repository_url
}

output "repository_arn" {
  description = "ARN of the created ECR repository."
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "Name of the created ECR repository."
  value       = aws_ecr_repository.main.name
}
