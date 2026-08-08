output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "eks_security_group_id" {
  description = "Security group ID for EKS"
  value       = aws_security_group.eks.id
}

output "database_security_group_id" {
  description = "Security group ID for databases"
  value       = aws_security_group.database.id
}
