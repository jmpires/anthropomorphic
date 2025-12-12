# eks.tf
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

  # Grant Jenkins IAM Role full cluster admin access
  map_roles = [
    {
      rolearn  = "arn:aws:iam::682882937469:role/JenkinsEKSRole"
      username = "jenkins-admin"
      groups   = ["system:masters"]
    }
  ]

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

# Get EKS cluster auth token
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}