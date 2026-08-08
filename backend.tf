# Uncomment and configure the backend after creating S3 bucket and DynamoDB table
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "infra/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-lock"
#   }
# }

# To use this backend:
# 1. Create an S3 bucket for state storage
# 2. Create a DynamoDB table named 'terraform-lock' with a primary key 'LockID'
# 3. Uncomment the configuration above
# 4. Run: terraform init
