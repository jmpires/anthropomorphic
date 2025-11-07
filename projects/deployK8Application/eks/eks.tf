# eks.tf
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 19.0"
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

      instance_types = ["t2.small"]
    }
  }
}
/*
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"
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

      instance_types = ["t2.small"]
    }
  }
}
*/