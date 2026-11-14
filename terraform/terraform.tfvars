# aws_region and environment are set by the pipeline (TF_VAR_*) from the
# selected GitHub Environment; defaults in variables.tf apply for local runs.
project_name = "istio-k8s"

vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

# POC / low-cost settings
kubernetes_version  = "1.35"
node_instance_types = ["t3.small", "t3a.small"] # 2 vCPU, 2 GiB each
node_capacity_type  = "SPOT"
node_count          = 2
node_disk_size      = 20

# Add your own IAM user/role here if it is different from the one the pipeline uses,
# so you can run kubectl locally:
# admin_principal_arns = ["arn:aws:iam::123456789012:user/your-user"]
