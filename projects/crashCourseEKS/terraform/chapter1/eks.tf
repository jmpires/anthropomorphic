# eks.tf

data "aws_caller_identity" "current" {}

locals {
  runner_arn = data.aws_caller_identity.current.arn
  admin_arn  = trimspace(var.eks_admin_principal_arn)
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = var.cluster_endpoint_public_access

  vpc_id     = module.eks-vpc.vpc_id
  subnet_ids = module.eks-vpc.private_subnets

  # --- ✅ EKS Access Entries (Kubernetes authorization) ---
  # 1) Whoever runs `terraform apply` becomes cluster-admin (terraform_runner).
  # 2) Optionally, a fixed principal (var.eks_admin_principal_arn) is ALSO admin,
  #    but only if it is set AND different from the runner (prevents 409 duplicates).
  access_entries = merge(
    {
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
    },
    local.admin_arn == "" || local.admin_arn == local.runner_arn ? {} : {
      eks_admin = {
        principal_arn = local.admin_arn

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
  )

  eks_managed_node_groups = {
    eks_node = {
      min_size       = var.eks_node_min_size
      max_size       = var.eks_node_max_size
      desired_size   = var.eks_node_desired_size
      instance_types = var.eks_node_instance_type
      ami_type       = var.eks_node_ami_type
    }
  }

  tags = {
    environment = var.tag_environment
    application = var.tag_application
  }
}
