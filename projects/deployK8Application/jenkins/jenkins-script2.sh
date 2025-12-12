#!/bin/bash
# Script name: jenkins-script.sh
# Description: This script installs Jenkins + required tooling on Amazon Linux 2
# OS supported: MacOS, Linux
# Author: Jorge Manuel Pires
# Contributors: Jorge Manuel Pires
# Initial Version.Last Updated(updates)  :v20251106.v20251212(6)

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
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip aws

# -------------------------------------------------
# Optional: verify all tools
aws --version
kubectl version --client
terraform -version
git --version
java -version
jenkins --version

# -------------------------------------------------
# ✅ NEW SECTION: Create and attach JenkinsEKSRole automatically
ROLE_NAME="JenkinsEKSRole"

echo "=== IAM Setup: Detect current EC2 instance ID ==="
EC2_INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "Detected instance ID: $EC2_INSTANCE_ID"

echo "=== IAM Setup: Create Jenkins IAM Role (if not exists) ==="
aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": { "Service": "ec2.amazonaws.com" },
                "Action": "sts:AssumeRole"
            }
        ]
    }' || echo "Role may already exist, continuing..."

echo "=== IAM Setup: Attach AdministratorAccess Policy ==="
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

echo "=== IAM Setup: Create Instance Profile (if not exists) ==="
aws iam create-instance-profile --instance-profile-name $ROLE_NAME || echo "Instance profile may already exist"

echo "=== IAM Setup: Add Role to Instance Profile ==="
aws iam add-role-to-instance-profile \
    --instance-profile-name $ROLE_NAME \
    --role-name $ROLE_NAME || echo "Role may already be attached"

echo "=== IAM Setup: Associate Instance Profile with EC2 ==="
aws ec2 associate-iam-instance-profile \
    --instance-id $EC2_INSTANCE_ID \
    --iam-instance-profile Name=$ROLE_NAME

echo "✅ IAM Setup complete. Jenkins EC2 now has AdministratorAccess through JenkinsEKSRole."
