# 📘 **Amazon EKS Crash Course: Cluster Upgrades and Lifecycle Management**


### 📖 Article Link
Read the full article set on Medium:

[Build an Amazon EKS Cluster with Terraform - EKS Crash Course (Chapter 1)](https://medium.com/towards-aws/build-an-amazon-eks-cluster-with-terraform-eks-crash-course-chapter-1-bd35a861d1ef)

[Upgrade Amazon EKS Using the AWS CLI: EKS Crash Course (Chapter 2)](https://medium.com/towards-aws/upgrade-an-amazon-eks-cluster-using-the-aws-cli-eks-crash-course-chapter-2-d8f43ad530f1)

[Upgrade Amazon EKS Using Terraform: EKS Crash Course (Chapter 3)](https://medium.com/towards-aws/upgrade-an-amazon-eks-cluster-using-terraform-eks-crash-course-chapter-3-6c73f717d3c6)

[Rethinking Node Scaling in Amazon EKS with Karpenter (Chapter 4)](<https://medium.com/towards-aws/rethinking-node-scaling-in-amazon-eks-with-karpenter-eks-crash-course-chapter-4-f482bde62def>)


### 📋 Code Structure

```
crashCourseEKS/
├── docs/                           # Architecture notes, diagrams, and operational guidance
├── terraform/
│   ├── chapter1
│   │   ├── backend.tf              # Remote Terraform state backend stored in S3 for centralized state management and collaboration.
│   │   ├── eks.tf                  # Defines the Amazon EKS cluster, managed node groups, and admin access configuration. 
│   │   ├── main.tf                 # Defines required providers and AWS provider configuration.
│   │   ├── output.tf               # Exposes key EKS and networking outputs for external use.
│   │   ├── terraform.tfvars        # Defines environment-specific variables for AWS, EKS, and VPC configuration.
│   │   ├── variables.tf            # Declares and validates input variables for AWS, EKS, node groups, and VPC configuration.
│   │   └── vpc.tf                  # Creates the VPC, subnets, and networking required for the EKS cluster.
│   │ 
│   ├── chapter2
│   │   ├── cli-commands.md         # EKS cluster upgrade procedure to Kubernetes 1.29 via CLI
│   │   └── README.md               # Project overview, prerequisites, and quick start instructions.
│   │ 
│   ├── chapter3
│   │   ├── bootstrap
│   │   │   ├── main.tf             # Defines required providers and AWS provider configuration.
│   │   │   ├── output.tf           # Exposes key EKS and networking outputs for external use.
│   │   │   ├── storage.tf          # Remote Terraform state backend stored in S3 for centralized state management + dynamo db lock.
│   │   │   ├── terraform.tfvars    # Defines environment-specific values.
│   │   │   └── variables.tf        # Declares and validates input variables for AWS, EKS, node groups, and VPC configuration.
│   │   └── eks
│   │       ├── addons.tf           # Manages core EKS add-ons and conflict resolution behavior.
│   │       ├── backend.hcl         # Supplies backend configuration parameters during Terraform initialization.
│   │       ├── backend.tf          # Defines remote state backend integration with S3 and DynamoDB locking.
│   │       ├── eks.tf              # Defines the EKS control plane, managed node groups, and lifecycle settings.
│   │       ├── main.tf             # Retrieves caller identity and defines shared local values.
│   │       ├── output.tf           # Exposes cluster metadata and infrastructure outputs.
│   │       ├── providers.tf        # Configures AWS and Kubernetes providers with EKS authentication.
│   │       ├── terraform.tfvars    # Defines environment-specific deployment values.
│   │       ├── variables.tf        # Declares and validates EKS deployment variables.
│   │       ├── versions.tf         # Specifies Terraform and provider version constraints.
│   │       └── vpc.tf              # Provisions the VPC, subnets, routing, and Kubernetes network tagging.
│   │ 
│   ├── chapter4
│   │   ├── tools
│   │   │   └── oneStep.sh          # Automates the end-to-end deployment, configuration, and validation of the EKS and Karpenter environment.
│   │   ├── yaml
│   │   │   ├── ec2nodeclass.yaml   # Defines the Karpenter EC2NodeClass for provisioning EC2 instances.
│   │   │   ├── inflate.yaml        # Deploys a sample workload to trigger Karpenter node provisioning.
│   │   │   └── nodepool.yaml       # Defines the Karpenter NodePool for dynamic node provisioning.
│   │   └── terraform
│   │       ├── backend.tf          # Remote Terraform state backend stored in S3 for centralized state management and collaboration.
│   │       ├── eks.tf              # Defines the Amazon EKS cluster, managed node groups, and admin access configuration.
│   │       ├── karpenter-irsa.tf    
│   │       ├── main.tf             # Defines required providers and AWS provider configuration.
│   │       ├── output.tf           # Exposes key EKS and networking outputs for external use.
│   │       ├── README.md           # Project overview, prerequisites, and quick start instructions.
│   │       ├── terraform.tfvars    # Defines environment-specific variables for AWS, EKS, and VPC configuration.
│   │       ├── variables.tf        # Declares and validates input variables for AWS, EKS, node groups, and VPC configuration.
│   │       └── vpc.tf              # Creates the VPC, subnets, and networking required for the EKS cluster.                   
│   │
│   ├── chapter5 ⚠️ WIP ⚠️ 
│
└── README.md                       # Project overview, prerequisites, and quick start instructions.
```