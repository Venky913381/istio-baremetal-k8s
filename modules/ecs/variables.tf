variable "project_name" {
  description = "The project name."
  type        = string
}

variable "environment" {
  description = "The deployment environment."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for ECS cluster service."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS service."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group ID for ECS service."
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "IAM Role ARN for ECS task execution."
  type        = string
}

variable "container_image" {
  description = "Docker image repository URL for ECS container."
  type        = string
}

variable "container_port" {
  description = "Port exposed by container."
  type        = number
  default     = 80
}

variable "target_group_arn" {
  description = "ALB Target Group ARN for ECS service."
  type        = string
}

variable "desired_count" {
  description = "Desired number of task instances."
  type        = number
  default     = 1
}
