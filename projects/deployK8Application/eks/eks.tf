module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.28" # 1.24 is deprecated — use 1.27+)

  vpc_id     = module.my-vpc.vpc_id
  subnet_ids = module.my-vpc.private_subnets

  # Public access config changed in v20+
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    dev = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.small"] # t2.small not supported in all regions for EKS
    }
  }

  tags = {
    environment = "development"
    application = "nginx-app"
  }
}