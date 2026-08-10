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

# Remote state inputs from VPC
data "terraform_remote_state" "vpc" {
  count   = var.vpc_id == "" || length(var.subnet_ids) == 0 ? 1 : 0
  backend = "local"

  config = {
    path = "${path.module}/../vpc/terraform.tfstate"
  }
}

# Remote state inputs from IAM
data "terraform_remote_state" "iam" {
  count   = var.cluster_role_arn == "" || var.node_role_arn == "" ? 1 : 0
  backend = "local"

  config = {
    path = "${path.module}/../iam/terraform.tfstate"
  }
}

locals {
  vpc_id           = var.vpc_id != "" ? var.vpc_id : data.terraform_remote_state.vpc[0].outputs.vpc_id
  subnet_ids       = length(var.subnet_ids) > 0 ? var.subnet_ids : data.terraform_remote_state.vpc[0].outputs.private_subnet_ids
  cluster_role_arn = var.cluster_role_arn != "" ? var.cluster_role_arn : data.terraform_remote_state.iam[0].outputs.eks_cluster_role_arn
  node_role_arn    = var.node_role_arn != "" ? var.node_role_arn : data.terraform_remote_state.iam[0].outputs.eks_node_role_arn
}

module "eks" {
  source = "../../../modules/eks"

  project_name     = var.project_name
  environment      = var.environment
  cluster_version  = var.cluster_version
  vpc_id           = local.vpc_id
  subnet_ids       = local.subnet_ids
  cluster_role_arn = local.cluster_role_arn
  node_role_arn    = local.node_role_arn
  desired_size     = var.desired_size
  max_size         = var.max_size
  min_size         = var.min_size
  instance_types   = var.instance_types
}
