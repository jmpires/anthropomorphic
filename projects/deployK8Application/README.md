# 📘 **Deploying a K8 application using Terraform, EKS Cluster and Jenkins**

### 📖 Article Link
Read the full article on Medium: [101 Setting Up a Kubernetes application using Terraform, EKS Cluster, Jenkins and GitHub actions](https://medium.com/towards-aws/101-setting-up-a-kubernetes-application-using-terraform-eks-cluster-github-actions-and-jenkins-bfe34a6f1125)


### 📋 Code Structure

deployK8Application/
.github/deploy-to-eks.yaml     # GitHub Actions workflow for automated EKS deployment

eks/

backend.tf             # Remote state backend for Terraform using S3
eks.tf                 # EKS cluster and managed node group configuration
output.tf              # Exports VPC public subnet IDs for use by dependent modules or external references
terraform.tfvars       # Environment-specific network CIDR definitions for VPC and subnets
variables.tf           # Input variable declarations for VPC and subnet CIDR blocks used in EKS networking
versions.tf            # Terraform version constraints and required provider declarations for AWS
vpc.tf                 # VPC, subnets, and networking configuration for EKS cluster

jenkins/

backend.tf             # Remote state backend for Terraform using S3
output.tf              # Exports VPC public subnet IDs for use by dependent modules or external references
provider.tf            # AWS provider configuration and version pinning for Jenkins infrastructure deployment
route.tf               # Internet gateway and default route table configuration for public connectivity in Jenkins VPC
security.tf            # Jenkins security group defining restricted ingress (SSH and UI) and unrestricted egress rules
server.tf              # Jenkins EC2 instance provisioning using Amazon Linux 2 AMI, with user-data bootstrap and security hardening
terraform.tfvar        # Jenkins-specific variable values (instance type, AMI, etc.)
variables.tf           # Input variable declarations for Jenkins infrastructure (VPC, subnet, AZ, instance type, and access control)
vpc.tf                 # Minimal VPC and private subnet definition for Jenkins infrastructure

jenkinsApply/

jenkinsApply/
Jenkinsfile        # Jenkins pipeline to deploy EKS and app via Terraform and kubectl

jenkinsDestroyEC2/
Jenkinsfile        # Jenkins pipeline to tear down EKS infrastructure using Terraform

jenkinsDestoryEKS/
Jenkinsfile        # Jenkins pipeline to destroy EKS cluster using Terraform

jenkinsOriginal/
Jenkinsfile        # Jenkins pipeline to provision EKS and deploy Kubernetes app

kubernetes/

nginx-deployment.yaml  # Application deployment manifest defining pod replicas and container specs
nginx-service.yaml     # Service definition for external access to the deployed application

tools/                     # A set of comprehensive tools for automation and utility functions

README.md                  # Project overview, prerequisites, and quick start instructions
