# variables.tf

variable "aws_region" {
  type        = string
  description = "AWS region"
  #default     = "us-east-1"
  default = null # Forces the user to supply a value via tfvars or CLI
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for Terraform state"
  default     = null # Forces the user to supply a value via tfvars or CLI
}

variable "log_bucket_name" {
  type        = string
  description = "S3 bucket name for access logs"
  #default     = "jmpires-terraform-state-logs" # Change as needed
  default = null # Forces the user to supply a value via tfvars or CLI
}

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB table for Terraform state locking"
  #default     = "terraform-state-lock"
  default = null # Forces the user to supply a value via tfvars or CLI
}