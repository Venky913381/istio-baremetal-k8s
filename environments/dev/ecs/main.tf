terraform {
  required_version = ">= 1.0"
  backend "s3" {}
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

# Remote state inputs from VPC
data "terraform_remote_state" "vpc" {
  count   = var.vpc_id == "" || length(var.subnet_ids) == 0 ? 1 : 0
  backend = "s3"

  config = {
    bucket = var.tf_state_bucket
    key    = "environments/${var.environment}/vpc/terraform.tfstate"
    region = var.aws_region
  }
}

# Remote state inputs from Security Groups
data "terraform_remote_state" "security_groups" {
  count   = var.security_group_id == "" ? 1 : 0
  backend = "s3"

  config = {
    bucket = var.tf_state_bucket
    key    = "environments/${var.environment}/security-groups/terraform.tfstate"
    region = var.aws_region
  }
}

# Remote state inputs from IAM
data "terraform_remote_state" "iam" {
  count   = var.ecs_task_execution_role_arn == "" ? 1 : 0
  backend = "s3"

  config = {
    bucket = var.tf_state_bucket
    key    = "environments/${var.environment}/iam/terraform.tfstate"
    region = var.aws_region
  }
}

# Remote state inputs from ALB
data "terraform_remote_state" "alb" {
  count   = var.target_group_arn == "" ? 1 : 0
  backend = "s3"

  config = {
    bucket = var.tf_state_bucket
    key    = "environments/${var.environment}/alb/terraform.tfstate"
    region = var.aws_region
  }
}

# Remote state inputs from ECR
data "terraform_remote_state" "ecr" {
  count   = var.container_image == "" ? 1 : 0
  backend = "s3"

  config = {
    bucket = var.tf_state_bucket
    key    = "environments/${var.environment}/ecr/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  vpc_id                      = var.vpc_id != "" ? var.vpc_id : data.terraform_remote_state.vpc[0].outputs.vpc_id
  subnet_ids                  = length(var.subnet_ids) > 0 ? var.subnet_ids : data.terraform_remote_state.vpc[0].outputs.public_subnet_ids
  security_group_id           = var.security_group_id != "" ? var.security_group_id : data.terraform_remote_state.security_groups[0].outputs.ecs_security_group_id
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn != "" ? var.ecs_task_execution_role_arn : data.terraform_remote_state.iam[0].outputs.ecs_task_execution_role_arn
  container_image             = var.container_image != "" ? var.container_image : data.terraform_remote_state.ecr[0].outputs.ecr_repository_url
  target_group_arn            = var.target_group_arn != "" ? var.target_group_arn : data.terraform_remote_state.alb[0].outputs.target_group_arn
}

module "ecs" {
  source = "../../../modules/ecs"

  project_name                = var.project_name
  environment                 = var.environment
  vpc_id                      = local.vpc_id
  subnet_ids                  = local.subnet_ids
  security_group_id           = local.security_group_id
  ecs_task_execution_role_arn = local.ecs_task_execution_role_arn
  container_image             = local.container_image
  container_port              = var.container_port
  target_group_arn            = local.target_group_arn
  desired_count               = var.desired_count
}
