# 📘 **Build an Amazon EKS Cluster with Terraform | EKS Crash Course (Chapter 1)**

### 📖 Article Link
Read the full article on Medium: [Build an Amazon EKS Cluster with Terraform | EKS Crash Course (Chapter 1)](<>)


### 📋 Code Structure

```
crashCourseEKS/
├── docs/                     # Architecture notes, diagrams, and operational guidance
├── terraform/
    └── chapter1
        ├── backend.tf        # Remote Terraform state backend stored in S3 for centralized state management and collaboration.
        ├── eks.tf            # Defines the Amazon EKS cluster, managed node groups, and admin access configuration. 
        ├── main.tf           # Defines required providers and AWS provider configuration.
        ├── output.tf         # Exposes key EKS and networking outputs for external use.
        ├── README.md         # Project overview, prerequisites, and quick start instructions.
        ├── terraform.tfvars  # Defines environment-specific variables for AWS, EKS, and VPC configuration.
        ├── variables.tf      # Declares and validates input variables for AWS, EKS, node groups, and VPC configuration.
        └── vpc.tf            # Creates the VPC, subnets, and networking required for the EKS cluster.
```
