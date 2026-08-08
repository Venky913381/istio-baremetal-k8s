# VPC Module

This module creates a VPC with public and private subnets, Internet Gateway, NAT Gateway, and route tables.

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
}
```

## Variables
