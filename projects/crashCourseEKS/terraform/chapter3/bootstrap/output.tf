# output.tf

output "state_bucket_name" {
  description = "Name of the S3 bucket for remote state"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

# [ADDED] Convenience Output
# Outputs the region so you don't have to look it up for the next step.
output "region" {
  description = "AWS region where infrastructure is deployed"
  value       = var.aws_region
}

# [ADDED] Optional: Log Bucket Name
# Useful for auditing or if you need to manage permissions later.
output "log_bucket_name" {
  description = "Name of the S3 bucket for access logs"
  value       = aws_s3_bucket.logs.id
}