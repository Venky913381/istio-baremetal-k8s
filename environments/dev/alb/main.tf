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

locals {
  vpc_id            = var.vpc_id != "" ? var.vpc_id : data.terraform_remote_state.vpc[0].outputs.vpc_id
  subnet_ids        = length(var.subnet_ids) > 0 ? var.subnet_ids : data.terraform_remote_state.vpc[0].outputs.public_subnet_ids
  security_group_id = var.security_group_id != "" ? var.security_group_id : data.terraform_remote_state.security_groups[0].outputs.alb_security_group_id
}

module "alb" {
  source = "../../../modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = local.vpc_id
  subnet_ids        = local.subnet_ids
  security_group_id = local.security_group_id
}
