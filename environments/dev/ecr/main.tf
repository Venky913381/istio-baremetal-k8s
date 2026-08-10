terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "ecr" {
  source = "../../../modules/ecr"

  project_name    = var.project_name
  environment     = var.environment
  repository_name = var.repository_name
}
