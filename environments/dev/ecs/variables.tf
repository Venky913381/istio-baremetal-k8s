variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "istio-baremetal-k8s"
}

variable "environment" {
  description = "The deployment environment."
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "Optional VPC ID override."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Optional Subnet IDs override."
  type        = list(string)
  default     = []
}

variable "security_group_id" {
  description = "Optional Security Group ID override."
  type        = string
  default     = ""
}

variable "ecs_task_execution_role_arn" {
  description = "Optional IAM Role ARN for ECS task execution."
  type        = string
  default     = ""
}

variable "container_image" {
  description = "Optional container image URL."
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Container port."
  type        = number
  default     = 80
}

variable "target_group_arn" {
  description = "Optional Target Group ARN."
  type        = string
  default     = ""
}

variable "desired_count" {
  description = "Desired number of task instances."
  type        = number
  default     = 1
}
