# backend.tf
terraform {
  # We define the backend type but omit specific keys
  backend "s3" {
    encrypt        = true
    # bucket, key, region, and dynamodb_table are passed via CLI
  }
}