#!/bin/bash

# -------------------------------------------------
# Jenkins Bootstrap Script
# Purpose: Install Jenkins + required tooling on Amazon Linux 2
# Principle: Technology shaped by human reasoning—not obscured by it.
# -------------------------------------------------

# Update system
sudo yum update -y

# -------------------------------------------------
# Install Java 17 (required by modern Jenkins)
# Jenkins >= 2.357 requires Java 17 or 21
# Using Amazon Corretto: official, LTS, and fully supported
# -------------------------------------------------
sudo yum install -y java-17-amazon-corretto-headless

# Verify Java installation (optional but explicit)
java -version

# -------------------------------------------------
# Install Jenkins from official stable repository
# -------------------------------------------------
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins

# Enable and start Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins

# -------------------------------------------------
# Install Git (required for SCM integration)
# -------------------------------------------------
sudo yum install -y git

# -------------------------------------------------
# Install Terraform (for infrastructure orchestration)
# -------------------------------------------------
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install -y terraform

# -------------------------------------------------
# Install kubectl (for EKS interaction)
# Uses latest stable version from official Kubernetes release channel
# -------------------------------------------------
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Optional: verify all tools
# java -version
# jenkins --version
# git --version
# terraform -version
# kubectl version --client