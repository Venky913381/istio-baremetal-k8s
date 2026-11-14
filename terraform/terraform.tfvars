# aws_region and environment are set by the pipeline (TF_VAR_*) from the
# selected GitHub Environment; defaults in variables.tf apply for local runs.
project_name = "istio-k8s"

vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

kubernetes_version  = "1.33"
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3

# Add your own IAM user/role here if it is different from the one the pipeline uses,
# so you can run kubectl locally:
# admin_principal_arns = ["arn:aws:iam::123456789012:user/your-user"]
