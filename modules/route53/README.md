# Route53 Module

This module creates Route53 hosted zones and DNS records.

## Usage

```hcl
module "route53" {
  source = "./modules/route53"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
}
```

## Variables

- `project_name`: The name of the project for tagging and naming resources.
- `environment`: The deployment environment (e.g., dev, stage, prod).
- `domain_name`: The domain name for which to create the Route53 hosted zone.