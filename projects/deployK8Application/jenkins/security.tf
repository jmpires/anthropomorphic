# security.tf
resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.my-vpc.id

  # SSH access — restricted to allowed IP
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip_cidr]
  }

  # Jenkins Web UI — restricted to allowed IP
  ingress {
    description = "Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip_cidr]
  }

  # Full egress — allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_prefix}-jenkins-sg"
  }
}