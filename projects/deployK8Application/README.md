# 📘 **Deploying a K8 application using Terraform, EKS Cluster and Jenkins**

### 📖 Article Link
[WIP] - Read the full article on Medium: [101 Setting Up a User Defined Kubernetes Cluster on AWS using Ubuntu Server and Terraform](https://medium.com/p/bfe34a6f1125/edit)


### 📋 Code Structure - Jenkins Server


## **Terraform files**

```
backend.tf - Terraform backend to store state file in an S3 bucket.

output.tf - Exposes key details of the deployed infrastructure after apply.

provider.tf - Defines AWS provider and region.

route.tf - Define an Internet Gateway and the default route table for our VPC.

security.tf - Defines a Security Group for our Jenkins server, allowing SSH access.

server.tf - Fetch image & define Jenkins server.

terraform.tfvars - Provide the values that we want to assign to the variables.

variables.tf - Specifies input variables to parameterize the configuration.

vpc - Define the VPC and a private subnet.
```

## **Bash files**

```
jenkins-script.sh - Implements the Jenkins, Git, Terraform and Kubectl logic
```


### 📋 Code Structure - EKS Cluster


## **Terraform files**

```
backend.tf - Terraform backend to store state file in an S3 bucket.

eks - Defines the structure of the EKS cluster.

outputs.tf - Exposes key details of the deployed infrastructure after apply.

terraform.tfvars - Provide the values that we want to assign to the variables.

variables.tf - Specifies input variables to parameterize the configuration.

versions.tf - Defines terraform and provider version's.

vpc - Define the VPC and a private subnet.
```

## **Bash files**
N/A

