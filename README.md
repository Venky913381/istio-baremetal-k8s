# AWS Infrastructure with Terraform

This directory contains the Terraform configuration for provisioning AWS infrastructure for Istio Bare Metal Kubernetes Lab.

## Project Structure

```
infra/
├── environments/
│   ├── dev/
│   ├── stage/
│   └── prod/
├── modules/
│   ├── vpc/
│   ├── eks/
│   ├── iam/
│   ├── alb/
│   ├── route53/
│   └── security-groups/
├── backend.tf
├── providers.tf
├── versions.tf
├── variables.tf
├── outputs.tf
└── README.md
```

## Directory Descriptions

### environments/
Contains environment-specific configurations:
- **dev/**: Development environment variables and terraform.tfvars
- **stage/**: Staging environment variables and terraform.tfvars
- **prod/**: Production environment variables and terraform.tfvars

### modules/
Reusable Terraform modules:
- **vpc/**: VPC, Subnets, NAT Gateway, Internet Gateway
- **eks/**: EKS Cluster and Node Groups
- **iam/**: IAM roles, policies, and service accounts
- **alb/**: Application Load Balancer configuration
- **route53/**: DNS records and hosted zones
- **security-groups/**: Security group rules and configurations

## Files

- **backend.tf**: Remote state configuration (S3 + DynamoDB)
- **providers.tf**: Provider configurations
- **versions.tf**: Required Terraform and provider versions
- **variables.tf**: Root module variables
- **outputs.tf**: Root module outputs

## Usage

### Initialize Terraform
```bash
terraform init
```

### Validate Configuration
```bash
terraform validate
```

### Plan Infrastructure
```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
```

### Apply Configuration
```bash
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### Destroy Infrastructure
```bash
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

## Prerequisites

- Terraform >= 1.6.0
- AWS CLI configured with appropriate credentials
- AWS Account with necessary permissions

## License

MIT
