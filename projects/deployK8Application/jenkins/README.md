# 📘 **Deploying a K8 application using Terraform, EKS Cluster and Jenkins**

### 📖 Article Link
N/A


### 📋 Code Structure


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

