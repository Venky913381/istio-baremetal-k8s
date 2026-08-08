# IAM Module

This module creates IAM roles and policies for EKS cluster and nodes.

## Usage

```hcl
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}
```

## Variables

- `project_name`: Project name for tagging
- `environment`: Environment (dev, stage, prod)

## Outputs

- `eks_cluster_role_arn`: ARN of the EKS cluster IAM role
- `eks_node_role_arn`: ARN of the EKS node IAM role
