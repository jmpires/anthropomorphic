# terraform.tfvars

# Review and adapt these values for your environment before applying.
# --- AWS global ---
aws_region              = "us-east-1"
aws_profile             = "jmpires"
aws_allowed_account_ids = ["682882937469"]

# --- EKS ---
cluster_name                   = "dev-eks-cluster"
cluster_version                = "1.28"
cluster_endpoint_public_access = true

# Optional fixed admin:
eks_admin_principal_arn = "arn:aws:iam::682882937469:user/jmpires"

# --- Tags ---
tag_environment = "development"
tag_application = "crash-course-eks"

# --- Node Group ---
eks_node_min_size      = 1
eks_node_max_size      = 3
eks_node_desired_size  = 2
eks_node_instance_type = ["t3.small"]
eks_node_ami_type      = "AL2023_x86_64_STANDARD"

# --- VPC ---
eks_vpc_name               = "dev-eks-vpc"
vpc_cidr_block             = "10.0.0.0/16"
private_subnet_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidr_blocks  = ["10.0.101.0/24", "10.0.102.0/24"]