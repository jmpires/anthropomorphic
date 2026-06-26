#!/bin/bash

clear

cd ~/skills/crashCourseEKS/terraform/chapter4

# Backing up tf files before modifying them for Karpenter installation
echo "Backing up karpenter.tf and providers.tf files..."
mv karpenter.tf karpenter.tf.backup
mv providers.tf providers.tf.backup

# Initialize Terraform, plan and apply changes
echo "Running Terraform commands..."
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply -auto-approve

# Update local kubeconfig with EKS cluster credentials
echo "Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig \
  --region us-east-1 \
  --profile jmpires \
  --name dev-eks-cluster

# Validate cluster connectivity
echo "Validating cluster connectivity..."
kubectl get nodes

# Validate OIDC provider creation
echo "Validating OIDC provider creation..."
 aws eks describe-cluster \
  --name dev-eks-cluster \
  --region us-east-1 \
  --query "cluster.identity.oidc.issuer" \
  --no-cli-pager

# Restore original Terraform configuration files
echo "Restoring original Terraform configuration files..."
mv karpenter.tf.backup karpenter.tf
mv providers.tf.backup providers.tf

# Initialize Terraform, plan and apply changes
echo "Updating Terraform configuration for Karpenter installation..."
terraform init -upgrade
terraform plan
terraform apply -auto-approve

# Update local kubeconfig with EKS cluster credentials
echo "Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig \
  --region us-east-1 \
  --profile jmpires \
  --name dev-eks-cluster

# Verify Karpenter installation
echo "Verifying Karpenter installation..."
kubectl get pods -n karpenter
kubectl get ns

# Modifying the role name in the ec2nodeclass.yaml file to match the IAM role created by Terraform
echo "Modifying the role name in ec2nodeclass.yaml..."
ROLE_NAME=$(terraform state show 'module.eks.module.eks_managed_node_group["eks_node"].aws_iam_role.this[0]' \
  | awk -F'"' '/^ *name *=/ {print $2}')
sed -i.bak "s|^\([[:space:]]*role:\).*|\1 ${ROLE_NAME}|" ../yaml/ec2nodeclass.yaml

# Deploy and Verify EC2NodeClass
echo "Deploying and verifying EC2NodeClass..."
kubectl apply -f ../yaml/ec2nodeclass.yaml
kubectl get ec2nodeclass
kubectl describe ec2nodeclass default | grep True

# Deploy and Verify NodePool
echo "Deploying and verifying NodePool..."
kubectl apply -f ../yaml/nodepool.yaml
kubectl get nodepool
kubectl describe nodepool default | grep True
kubectl get nodeclaims

# Verify the security groups and subnets associated with the EC2NodeClass
echo "Verifying security groups and subnets associated with the EC2NodeClass..."
kubectl get ec2nodeclass default -o yaml | grep -A20 securityGroups:
kubectl get ec2nodeclass default -o yaml | grep -A20 subnets:

# Verify that there are no leftover NodeClaims before we trigger provisioning
echo "Verifying that there are no leftover NodeClaims..."
kubectl get nodeclaims