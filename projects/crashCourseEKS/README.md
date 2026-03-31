# 📘 **Amazon EKS Crash Course: Cluster Upgrades and Lifecycle Management**

### 📖 Article Link
Read the full article set on Medium:

[Build an Amazon EKS Cluster with Terraform - EKS Crash Course (Chapter 1)](https://medium.com/towards-aws/build-an-amazon-eks-cluster-with-terraform-eks-crash-course-chapter-1-bd35a861d1ef)

[Upgrade Amazon EKS Using the AWS CLI: EKS Crash Course (Chapter 2)](<LINK>)

[Upgrade Amazon EKS Using Terraform: EKS Crash Course (Chapter 3)](<LINK>)


### 📋 Code Structure

```
crashCourseEKS/
├── docs/                     # Architecture notes, diagrams, and operational guidance
├── terraform/
│   ├── chapter1
│   │   ├── backend.tf        # Remote Terraform state backend stored in S3 for centralized state management and collaboration.
│   │   ├── eks.tf            # Defines the Amazon EKS cluster, managed node groups, and admin access configuration. 
│   │   ├── main.tf           # Defines required providers and AWS provider configuration.
│   │   ├── output.tf         # Exposes key EKS and networking outputs for external use.
│   │   ├── terraform.tfvars  # Defines environment-specific variables for AWS, EKS, and VPC configuration.
│   │   ├── variables.tf      # Declares and validates input variables for AWS, EKS, node groups, and VPC configuration.
│   │   └── vpc.tf            # Creates the VPC, subnets, and networking required for the EKS cluster.
│   │ 
│   ├── chapter2
│   │   ├── cli-commands.md   # EKS cluster upgrade procedure to Kubernetes 1.29 via CLI
│   │   └── README.md         # Project overview, prerequisites, and quick start instructions.

...

└── README.md                 # Project overview, prerequisites, and quick start instructions.
```