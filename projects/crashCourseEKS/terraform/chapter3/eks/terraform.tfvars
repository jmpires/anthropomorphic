region          = "us-east-1"

cluster_name    = "enterprise-eks"
cluster_version = "1.29"

vpc_name = "eks-vpc"
vpc_cidr = "10.0.0.0/16"

private_subnets = ["10.0.1.0/24","10.0.2.0/24"]
public_subnets  = ["10.0.101.0/24","10.0.102.0/24"]

node_desired = 2
node_min     = 1
node_max     = 3

instance_types = ["t3.small"]