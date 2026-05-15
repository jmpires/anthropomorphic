# backend.hcl

bucket         = "jmpires-eks-bucket" # Change to your bucket name
key            = "eks/terraform.tfstate" 
region         = "us-east-1"
dynamodb_table = "terraform-state-lock"