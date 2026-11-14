# Remote state in S3 with native S3 locking (no DynamoDB table needed).
# The bucket must exist before `terraform init`. Bucket/region can be
# overridden at init time with -backend-config (the pipeline does this).
terraform {
  backend "s3" {
    bucket       = "istio-baremetal-k8s-tfstate"
    key          = "fresh-start/eks/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
