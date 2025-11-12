terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region  = var.region_id
  profile = var.aws_profile
}

data "aws_region" "current" {}

# Generate a new key pair and save the private key to a file
resource "tls_private_key" "KeyPair" {
  algorithm = var.algorithm_id
  rsa_bits  = var.rsa_bits_id
}

# Creating keypair and setting secure permissions (chmod 400)
resource "local_file" "KeyPair_pem" {
  content  = tls_private_key.KeyPair.private_key_pem
  filename = "${path.module}/${var.key_pair_filename}"

  provisioner "local-exec" {
    command = "chmod 400 ${self.filename}"
  }

  # Optional: Add lifecycle to prevent accidental deletion
  lifecycle {
    prevent_destroy = false # Temporarily set to false. Set to true to avoid accidental destroy.
  }
}

resource "aws_key_pair" "KeyPair" {
  key_name   = var.aws_key_pair_id
  public_key = tls_private_key.KeyPair.public_key_openssh
}

# Data source to fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Subnet resources for control plane and worker nodes
resource "aws_subnet" "k8s_workers" {
  count                   = length(var.availability_zones)
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = cidrsubnet(data.aws_vpc.default.cidr_block, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-worker-${var.availability_zones[count.index]}"
  }
}

# Simple flat list of instances based on total_instances
locals {
  instances = {
    for i in range(var.total_instances) : "node-${i}" => {
      name          = i == 0 ? "k8-ControlPlane" : "k8-WorkerNode-${i}"
      instance_type = i == 0 ? var.control_plane_instance_type : var.worker_instance_type
      ami           = var.default_ami
      role          = i == 0 ? "control-plane" : "worker"
    }
  }
}

# Create a new security group with SSH & HTTP access
resource "aws_security_group" "k8SecurityGroup" {
  name        = var.aws_security_group_id
  description = "Allow SSH access from anywhere"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins port
  ingress {
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API server (control plane) - allow from cluster nodes
  ingress {
    from_port = 6443
    to_port   = 6443
    protocol  = "tcp"
    self      = true # ← Allows traffic from any instance with this same SG
  }

  # Allow internal node-to-node traffic(for CNI, kubelet, etc.)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1" # all protocols
    self      = true
  }
  # NodePort range (for testing services, e.g. nginx)
  ingress {
  from_port   = var.nodeport_range_start
  to_port     = var.nodeport_range_end
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  # Outbound traffic 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.aws_security_group_id
  }
}

resource "aws_instance" "k8s_node" {
  for_each               = local.instances
  ami                    = each.value.ami
  instance_type          = each.value.instance_type
  key_name               = var.aws_key_pair_id
  vpc_security_group_ids = [aws_security_group.k8SecurityGroup.id]
  subnet_id              = aws_subnet.k8s_workers[0].id  # Use first subnet ID for all instances

  root_block_device {
    volume_size           = 20 # Increased for Kubernetes (10GB is often too small)
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = false
  }

  tags = {
    Name = each.value.name
    Role = each.value.role
  }
}