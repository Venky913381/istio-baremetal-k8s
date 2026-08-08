# Staging Environment

Staging environment configuration for Istio Bare Metal Kubernetes Lab.

## Variables

Update `terraform.tfvars` with staging-specific values.

## Deployment

```bash
terraform plan -var-file="environments/stage/terraform.tfvars"
terraform apply -var-file="environments/stage/terraform.tfvars"
```
