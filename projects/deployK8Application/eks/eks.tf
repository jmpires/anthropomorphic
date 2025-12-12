#######################################################
# eks.tf - Terraform configuration for EKS cluster
# Version: Terraform AWS EKS Module ~> 19.0
# Cluster version: 1.28
#######################################################

# -----------------------------
# Root-level variables
# -----------------------------
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "jenkins-eks-cluster"
}

# -----------------------------
# EKS Cluster Module
# -----------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"

  cluster_endpoint_public_access = true

  vpc_id     = module.my-vpc.vpc_id
  subnet_ids = module.my-vpc.private_subnets

  tags = {
    environment = "development"
    application = "nginx-app"
  }

  eks_managed_node_groups = {
    eks_node = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"
    }
  }
}

# -----------------------------
# Optional: Output the cluster info
# -----------------------------
output "cluster_id" {
  value       = module.eks.cluster_id
  description = "EKS cluster ID"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster endpoint"
}

output "cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "Cluster security group ID"
}
