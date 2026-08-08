# Staging Environment Variables

aws_region   = "us-east-1"
project_name = "istio-baremetal-k8s"
environment  = "stage"
vpc_cidr     = "10.1.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

enable_nat_gateway = true
single_nat_gateway = false
