# storage.tf

# --- S3 Bucket for Logs (Self-Contained) --------------------------

# Creates the logging bucket first
resource "aws_s3_bucket" "logs" {
  bucket = var.log_bucket_name

  # TEMPORARY: Allow deletion for cleanup
  #force_destroy = true

  # [Layer 2] Terraform Logic Protection
  # Prevents Terraform from destroying the resource.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "logs_versioning" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Secure the log bucket as well
resource "aws_s3_bucket_public_access_block" "logs_block" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- S3 Bucket for State --------------------------

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  # TEMPORARY: Allow deletion for cleanup
  #force_destroy = true

  # [Layer 2] Terraform Logic Protection
  # Prevents Terraform from destroying the resource.
  lifecycle {
    prevent_destroy = true
  }
}

# FIX: Moved logging configuration to separate resource for Provider v5
resource "aws_s3_bucket_logging" "state_logging" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "log/${var.bucket_name}/"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Security: Enforce strict public access blocking
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Operations: Manage state file lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "state_lifecycle" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "state-cleanup"
    status = "Enabled"

    # FIX APPLIED: Added filter to suppress warning and apply to all objects
    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# --- Dynamo Lock Table --------------------------

resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  # [Layer 1] AWS Native Protection
  # Prevents deletion via AWS API/Console unless explicitly disabled
  deletion_protection_enabled = true
  #deletion_protection_enabled = false

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  # [Layer 2] Terraform Logic Protection
  # Prevents Terraform from destroying the resource.
  # If you run 'terraform destroy', this resource will error out safely.
  # Uncomment the lifecycle block to enable it.

  lifecycle {
    prevent_destroy = true
  }
}