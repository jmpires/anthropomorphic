module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"
  # version = "~> 20.0"

  cluster_name    = "jenkins-eks-cluster"
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
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.small"]

      # Required for EKS 1.28+
      ami_type = "AL2023_x86_64_STANDARD"
    }
  }
}
