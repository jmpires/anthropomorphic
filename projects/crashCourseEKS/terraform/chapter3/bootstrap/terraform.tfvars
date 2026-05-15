# terraform.tfvars

# Review and adapt these values for your environment before applying.
# --- AWS global ---
aws_region = "us-east-1"

# --- S3 Bucket ---
bucket_name     = "jmpires-eks-bucket"           # Change to a unique name
log_bucket_name = "jmpires-terraform-state-logs" # Change to a unique name

# --- DynamoDB table state locking ---
dynamodb_table_name = "terraform-state-lock" # Change to a unique name