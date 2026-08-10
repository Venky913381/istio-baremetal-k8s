variable "project_name" {
  description = "The project name."
  type        = string
}

variable "environment" {
  description = "The deployment environment."
  type        = string
}

variable "repository_name" {
  description = "Name of the ECR repository."
  type        = string
  default     = "app"
}
