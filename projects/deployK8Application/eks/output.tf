# output.tf
output "public_subnets" {
  value =  module.my-vpc.public_subnets
}