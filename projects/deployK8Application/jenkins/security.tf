# security.tf

# Optional: Define your public IP as a variable (recommended)
# If you don't already have it, add this to variables.tf:
# variable "allowed_ip_cidr" {
#   description = "CIDR block allowed to access SSH and Jenkins (e.g., your public IP)"
#   type        = string
#   default     = "0.0.0.0/0"  # Override in tfvars or CLI for security
# }

resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.my-vpc.id

  # SSH access — restricted to allowed IP
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip_cidr]
    # Optional: remove IPv6 if not needed
    # ipv6_cidr_blocks = [var.allowed_ipv6_cidr]
  }

  # Jenkins Web UI — restricted to allowed IP
  ingress {
    description = "Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip_cidr]
    # ipv6_cidr_blocks = [var.allowed_ipv6_cidr]
  }

  # Full egress — allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.env_prefix}-jenkins-sg"
  }
}