# Security Groups Module

This module creates security groups for VPC resources like ALB, EKS, and databases.

## Usage

```hcl
module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}
```

## Variables

- `project_name`: Project name for tagging
- `environment`: Environment (dev, stage, prod)
- `vpc_id`: VPC ID

## Outputs

- `alb_security_group_id`: Security group ID for ALB
- `eks_security_group_id`: Security group ID for EKS
- `database_security_group_id`: Security group ID for databases
