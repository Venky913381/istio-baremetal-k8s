# Production Environment

Production environment configuration for Istio Bare Metal Kubernetes Lab.

## Variables

Update `terraform.tfvars` with production-specific values.

## Deployment

```bash
terraform plan -var-file="environments/prod/terraform.tfvars"
terraform apply -var-file="environments/prod/terraform.tfvars"
```
