# variables.tf

# --- Global Variables --------------------------
variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile name to use for deployment (e.g., myprofile)"

  validation {
    condition     = length(trimspace(var.aws_profile)) > 0
    error_message = "aws_profile must be a non-empty string (e.g., \"default\")."
  }
}

variable "aws_allowed_account_ids" {
  type        = list(string)
  description = "Allowed AWS account IDs (safety check to prevent applying to the wrong account)"

  validation {
    condition     = length(var.aws_allowed_account_ids) > 0
    error_message = "aws_allowed_account_ids must contain at least one AWS account ID."
  }

  validation {
    condition     = alltrue([for id in var.aws_allowed_account_ids : can(regex("^\\d{12}$", id))])
    error_message = "Each aws_allowed_account_ids entry must be a 12-digit AWS account ID (e.g., \"0123456789012\")."
  }
}

# --- EKS Variables --------------------------
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "dev-eks-cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
  default     = "1.28"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Whether the cluster endpoint should be publicly accessible"
  default     = false
}

# Optional fixed admin principal.
# Leave empty ("") to disable static admin and rely only on terraform_runner.
variable "eks_admin_principal_arn" {
  type        = string
  description = "Optional: IAM user/role ARN to always grant EKS cluster-admin. Leave empty to disable."
  default     = ""

  validation {
    condition = (
      trimspace(var.eks_admin_principal_arn) == "" ||
      can(regex("^arn:aws:iam::\\d{12}:(user|role)\\/.+$", trimspace(var.eks_admin_principal_arn)))
    )
    error_message = "eks_admin_principal_arn must be empty or a valid IAM user/role ARN (arn:aws:iam::<acct>:(user|role)/...)."
  }
}

variable "tag_environment" {
  type        = string
  description = "Environment tag for resources"
  default     = "development"
}

variable "tag_application" {
  type        = string
  description = "Application tag for resources"
  default     = "2BeDefined"
}

variable "eks_node_min_size" {
  type        = number
  description = "Minimum number of nodes in the EKS managed node group"
  default     = 1
}

variable "eks_node_max_size" {
  type        = number
  description = "Maximum number of nodes in the EKS managed node group"
  default     = 3
}

variable "eks_node_desired_size" {
  type        = number
  description = "Desired number of nodes in the EKS managed node group"
  default     = 2
}

variable "eks_node_instance_type" {
  type        = list(string)
  description = "Instance types for the EKS managed node group"
  default     = ["t3.small"]
}

variable "eks_node_ami_type" {
  type        = string
  description = "AMI type for the EKS managed node group"
  default     = "AL2023_x86_64_STANDARD"
}

# --- VPC Variables --------------------------
variable "eks_vpc_name" {
  type        = string
  description = "Name of the EKS VPC"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR (must not overlap with existing VPCs in account)"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "Invalid CIDR block format (e.g., 10.0.0.0/16)."
  }
}

variable "private_subnet_cidr_blocks" {
  type        = list(string)
  description = "Private subnets across ≥2 AZs (must be within vpc_cidr_block)"

  validation {
    condition     = length(var.private_subnet_cidr_blocks) >= 2
    error_message = "At least 2 private subnets are required for HA across AZs."
  }
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  description = "Public subnets (typically 1 per AZ)"
}