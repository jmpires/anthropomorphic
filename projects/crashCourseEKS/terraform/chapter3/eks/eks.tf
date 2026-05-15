# eks.tf

module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Prevent duplicate automatic creator access entries.
  # Access management is handled explicitly via access_entries.
  enable_cluster_creator_admin_permissions = false

  # SECURITY:
  # Public endpoint enabled for learning/lab accessibility.
  # Production environments should restrict CIDRs or use private endpoints only.
  cluster_endpoint_public_access = true

  # Example production hardening:
  # cluster_endpoint_public_access_cidrs = ["1.2.3.4/32"]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enable control plane logging for auditing and troubleshooting
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Managed Node Group Configuration
  eks_managed_node_groups = {

    default = {

      name           = "primary"
      instance_types = var.instance_types
      ami_type       = "AL2023_x86_64_STANDARD"

      min_size     = var.node_min
      max_size     = var.node_max
      desired_size = var.node_desired

      # Controlled rolling updates
      update_config = {
        max_unavailable_percentage = 33
      }

      labels = {
        Environment = "enterprise"
      }

      tags = {
        NodeGroup = "primary"
      }
    }
  }

  # Enable IRSA/OIDC integration
  # Required for modern Kubernetes identity federation patterns
  enable_irsa = true

  # Explicit EKS access management
  access_entries = {

    terraform_runner = {

      principal_arn = local.runner_arn

      policy_associations = {

        admin = {

          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    managed-by = "terraform"
    environment = "enterprise"
  }
}