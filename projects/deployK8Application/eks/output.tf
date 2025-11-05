# output.tf
output "public_subnets" {
  value = module.my-vpc.public_subnets
  #value = terraform.tfvars.public_subnet_cidr_blocks
}