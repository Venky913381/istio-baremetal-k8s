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

- `project_name`: The name of the project for tagging and naming resources.
- `environment`: The deployment environment (e.g., dev, stage, prod).
