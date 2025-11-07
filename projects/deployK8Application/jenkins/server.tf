# server.tf

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "my-server" {
  ami                         = data.aws_ami.latest-amazon-linux-image.id
  instance_type               = var.instance_type
  key_name                    = "global-key-pair"
  subnet_id                   = aws_subnet.jenkins-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  availability_zone           = var.availability_zone
  associate_public_ip_address = true
  user_data                   = file("jenkins-script.sh")
  tags = {
    Name = "${var.env_prefix}-server"
  }
}