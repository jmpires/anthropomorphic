# output.tf
output "ec2_public_ip" {
  value = aws_instance.my-server.public_ip
}