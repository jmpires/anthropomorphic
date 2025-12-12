module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "jenkins-eks-cluster"
  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  vpc_id     = module.my-vpc.vpc_id
  subnet_ids = module.my-vpc.private_subnets

  tags = {
    environment = "development"
    application = "nginx-app"
  }

  # -------------------------------
  # Give Jenkins EC2 instance access
  # -------------------------------
  cluster_access_entries = {
    jenkins_ec2_role = {
      principal_arn     = "arn:aws:iam::682882937469:role/JenkinsEKSRole" # replace with your EC2 instance role
      kubernetes_groups = ["system:masters"]
    }
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
