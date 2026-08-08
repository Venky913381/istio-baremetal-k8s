terraform {
  backend "s3" {
    # The bucket name and DynamoDB table name should be unique.
    # These resources should be created before you can initialize this backend.
    # It's a good practice to manage these bootstrap resources in a separate, simpler
    # Terraform configuration.
    bucket         = "istio-baremetal-k8s-tfstate"
    key            = "env:/${terraform.workspace}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "istio-baremetal-k8s-tf-lock"
  }
}

# To use this backend:
# 1. Create an S3 bucket (e.g., "istio-baremetal-k8s-tfstate").
# 2. Create a DynamoDB table (e.g., "istio-baremetal-k8s-tf-lock") with a primary key 'LockID' of type String.
# 3. Run `terraform init`.
# 4. Use workspaces to manage environments: `terraform workspace new dev`
# 5. Then run `terraform apply` for the specific environment.
