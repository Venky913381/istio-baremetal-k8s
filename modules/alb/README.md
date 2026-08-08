# ALB Module

This module creates an Application Load Balancer with target groups and listeners.

## Usage

```hcl
module "alb" {
  source = "./modules/alb"

  project_name   = var.project_name
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_security_group_id
}
```

## Variables

- `project_name`: Project name for tagging
- `environment`: Environment (dev, stage, prod)
- `vpc_id`: VPC ID
- `subnet_ids`: Subnet IDs for the ALB
- `security_group_id`: Security group ID for the ALB

## Outputs

- `alb_arn`: ARN of the Application Load Balancer
- `alb_dns_name`: DNS name of the ALB
- `target_group_arn`: ARN of the target group
