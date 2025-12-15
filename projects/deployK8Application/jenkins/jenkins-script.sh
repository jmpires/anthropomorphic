#!/bin/bash
# Script name: jenkins-script.sh
# Description: This script installs Jenkins + required tooling on Amazon Linux 2
# OS supported: MacOS, Linux
# Author: Jorge Manuel Pires
# Contributors: Jorge Manuel Pires
# Initial Version.Last Updated(updates)	:v20251106.v20251212(6)

# For debugging purposes
# set -x

set -e

# -------------------------------------------------
# Update package repository and installed packages
sudo yum update -y

# -------------------------------------------------
# Install Java 17 (required by modern Jenkins)
sudo yum install -y java-17-amazon-corretto-headless
java -version

# -------------------------------------------------
# Install Jenkins from official stable repository
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# -------------------------------------------------
# Install Git
sudo yum install -y git

# -------------------------------------------------
# Install Terraform
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install -y terraform

# -------------------------------------------------
# Install latest kubectl
LATEST_KUBECTL=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${LATEST_KUBECTL}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# -------------------------------------------------
# Install AWS CLI v2 (required for EKS authentication)
# 1. Remove AWS CLI v1 if present
sudo yum remove awscli -y 2>/dev/null || true
# 2. Download and install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip aws/
# 3. Verify (no symlink needed)
aws --version  # ✅ Now resolves to v2 via standard PATH
# sudo ln -s /usr/local/bin/aws /usr/bin/aws

# -------------------------------------------------
# Optional: verify all tools
aws --version
kubectl version --client
terraform -version
git --version
java -version
jenkins --version