#!/bin/bash
set -e

# Install Java 17 (Amazon Corretto)
echo "=== Installing Java 17 (Amazon Corretto) ==="
sudo yum update -y
sudo yum install -y java-17-amazon-corretto-devel

# Verify Java 17 installation
echo "=== Verifying Java 17 ==="
JAVA17_PATH="/usr/lib/jvm/java-17-amazon-corretto/bin/java"
if [ ! -f "$JAVA17_PATH" ]; then
  echo "ERROR: Java 17 not found at expected path"
  exit 1
fi
$JAVA17_PATH -version

# Install Jenkins
echo "=== Installing Jenkins ==="
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins

#echo "=== Configuring Jenkins to use Java 17 ==="
#sudo sed -i "s|^JENKINS_JAVA_CMD=.*|JENKINS_JAVA_CMD=\"$JAVA17_PATH\"|" /etc/sysconfig/jenkins

# Start Jenkins service
echo "=== Starting Jenkins ==="
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Wait for Jenkins to initialize (about 1 minute)
echo "=== Waiting for Jenkins to initialize ==="
sleep 60

#echo "=== Jenkins admin password ==="
#sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Install Git
echo "=== Installing Git ==="
sudo yum install git -y

# Install Terraform
echo "=== Installing Terraform ==="
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

# Install kubectl
echo "=== Installing kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl