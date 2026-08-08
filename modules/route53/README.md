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

- `project_name`: Project name for tagging
- `environment`: Environment (dev, stage, prod)
- `domain_name`: Domain name for the hosted zone

## Outputs

- `hosted_zone_id`: ID of the hosted zone
- `name_servers`: Name servers for the hosted zone
