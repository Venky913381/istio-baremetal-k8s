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

- `project_name`: Project name for tagging
- `environment`: Environment (dev, stage, prod)
- `vpc_cidr`: CIDR block for VPC
- `availability_zones`: List of AZs
- `enable_nat_gateway`: Enable NAT Gateway
- `single_nat_gateway`: Use single NAT or one per AZ

## Outputs

- `vpc_id`: ID of the VPC
- `vpc_cidr`: CIDR block of the VPC
- `public_subnet_ids`: IDs of public subnets
- `private_subnet_ids`: IDs of private subnets
