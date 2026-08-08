# Development Environment

Development environment configuration for Istio Bare Metal Kubernetes Lab.

## Variables

Update `terraform.tfvars` with development-specific values.

## Deployment

```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"
```
