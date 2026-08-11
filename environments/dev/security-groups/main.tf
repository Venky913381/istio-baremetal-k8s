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

# Remote state to get VPC details if vpc_id is not explicitly provided
data "terraform_remote_state" "vpc" {
  count   = var.vpc_id == "" ? 1 : 0
  backend = "s3"

  config = {
    bucket = var.tf_state_bucket
    key    = "environments/${var.environment}/vpc/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  vpc_id   = var.vpc_id != "" ? var.vpc_id : data.terraform_remote_state.vpc[0].outputs.vpc_id
  vpc_cidr = var.vpc_cidr != "" ? var.vpc_cidr : try(data.terraform_remote_state.vpc[0].outputs.vpc_cidr, "10.0.0.0/16")
}

module "security_groups" {
  source = "../../../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = local.vpc_id
  vpc_cidr     = local.vpc_cidr
}
