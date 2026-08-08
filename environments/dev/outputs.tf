output "eks_cluster_endpoint" {
  description = "Endpoint for EKS cluster."
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "alb_dns_name" {
  description = "DNS name of the ALB."
  value       = module.alb.dns_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for the application."
  value       = module.ecr.repository_url
}