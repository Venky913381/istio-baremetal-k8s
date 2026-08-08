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

- `project_name`: The name of the project for tagging and naming resources.
- `environment`: The deployment environment (e.g., dev, stage, prod).
- `vpc_id`: The ID of the VPC where the security groups will be created.