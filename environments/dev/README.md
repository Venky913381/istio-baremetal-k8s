# Development Environment (Resource-Specific Folders)

This directory contains the resource-specific Terraform configurations for the **Development (dev)** environment. Each resource stack has its own independent folder so you can provision or destroy specific AWS resources independently instead of applying all infrastructure at once.

---

## Directory Structure

```text
environments/dev/
├── vpc/                # VPC, Internet Gateway, Subnets, NAT Gateway
├── iam/                # IAM Roles for EKS Cluster, EKS Nodes & ECS Tasks
├── security-groups/    # Security Groups (ALB, EKS, DB, ECS)
├── alb/                # Application Load Balancer & Target Groups
├── eks/                # EKS Cluster & Managed Node Group
├── route53/            # Route53 Hosted Zone & Health Checks
├── ecr/                # Elastic Container Registry Repository
└── ecs/                # ECS Cluster, Task Definition & Fargate Service
```

Each folder contains:
- `main.tf`: Provider setup, data sources / remote state references, and module invocations.
- `variables.tf`: Input variable definitions.
- `terraform.tfvars`: Environment-specific variable assignments for `dev`.
- `outputs.tf`: Exported attributes for downstream consumption.

---

## Recommended Deployment Order

Because certain resources depend on others (e.g. Security Groups need VPC ID, EKS needs IAM roles and subnets), apply the stacks in the following sequence:

1. **VPC Stack**:
   ```bash
   cd environments/dev/vpc
   terraform init
   terraform apply
   ```

2. **IAM Stack**:
   ```bash
   cd environments/dev/iam
   terraform init
   terraform apply
   ```

3. **Security Groups Stack**:
   ```bash
   cd environments/dev/security-groups
   terraform init
   terraform apply
   ```

4. **ALB Stack**:
   ```bash
   cd environments/dev/alb
   terraform init
   terraform apply
   ```

5. **EKS Stack**:
   ```bash
   cd environments/dev/eks
   terraform init
   terraform apply
   ```

6. **Route53 Stack**:
   ```bash
   cd environments/dev/route53
   terraform init
   terraform apply
   ```

7. **ECR Stack** *(Optional)*:
   ```bash
   cd environments/dev/ecr
   terraform init
   terraform apply
   ```

8. **ECS Stack** *(Optional)*:
   ```bash
   cd environments/dev/ecs
   terraform init
   terraform apply
   ```

---

## How Inter-Resource Dependency Resolution Works

Each stack reads outputs from upstream local state files automatically via `terraform_remote_state` (or fallback input variables in `terraform.tfvars`).

If you want to manually override any value (for example, point to an existing VPC ID), simply pass it in that folder's `terraform.tfvars` file:

```hcl
vpc_id = "vpc-0123456789abcdef0"
```
