# EKS Module

This module creates an Amazon EKS cluster with managed node groups.

## Usage

```hcl
module "eks" {
  source = "./modules/eks"

  project_name       = var.project_name
  environment        = var.environment
  cluster_version    = "1.28"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  cluster_role_arn   = module.iam.eks_cluster_role_arn
  node_role_arn      = module.iam.eks_node_role_arn
}
```

## Variables

- `project_name`: Project name for tagging
- `environment`: Environment (dev, stage, prod)
- `cluster_version`: Kubernetes version
- `vpc_id`: VPC ID
- `subnet_ids`: Subnet IDs for the cluster
- `cluster_role_arn`: IAM role ARN for EKS cluster
- `node_role_arn`: IAM role ARN for nodes

## Outputs

- `cluster_id`: EKS cluster ID
- `cluster_arn`: EKS cluster ARN
- `cluster_endpoint`: EKS cluster endpoint
- `cluster_security_group_id`: Security group ID of the cluster
