# 📖 **Learning Logs**


### 📋 AWS Account & Permissions

You must have:
- An active AWS account ([sign up](https://aws.amazon.com/))


📚 [Set up your AWS account and credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) (AWS Official Guide)  
⚠️ **Do not use root account credentials.** This lab uses EKS and EC2 resources that **are not covered by the AWS Free Tier**. You will incur charges—always run `terraform destroy` to clean up when finished. ⚠️

- Programmatic access via an IAM user (not root) with access key and secret
- Sufficient permissions (e.g., `AdministratorAccess` or a custom policy granting actions for **EC2, EKS, IAM, VPC, S3, and CloudWatch**)
- [AWS CLI configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) locally (`aws configure`)

### 📋 Knowledge & Experience

**AWS**
🔗 [AWS fundamentals: launching EC2 instances, VPCs, IAM roles, and security groups.](https://aws.amazon.com/training/learn-about/cloud-practitioner)
🔗 [Set up your AWS account and credentials (AWS Official Guide).](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)


**Bash scripting**
🔗 [Bash scripting](https://tldp.org/LDP/Bash-Beginners-Guide/html/?spm=a2ty_o01.29997173.0.0.3cc2c92115XL0c)


**GitHub Actions**

🔗 [EKS](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)


**Git & GitHub basics**

🔗 [Git & GitHub basics](https://skills.github.com/?spm=a2ty_o01.29997173.0.0.3cc2c92115XL0c)


**GitHub Actions**

🔗 [GitHub Actions](https://docs.github.com/en/actions/get-started/understand-github-actions)


**Jenkins Handbook**

🔗 [Jenkins Handbook](https://www.jenkins.io/doc/book/?spm=a2ty_o01.29997173.0.0.10495171PK2nWS#jenkins-handbook)


**jq Manual**

🔗 [jq Manual](https://jqlang.org/manual)


**Kubernetes**

🔗 [Kubernetes concepts](https://kubernetes.io/docs/tutorials/kubernetes-basics)


**Terraform**

🔗 [Terraform basics](https://developer.hashicorp.com/terraform/tutorials)

#

### 📋 Tools & Versions

**AWS**

🔗 [AWS CLI v2.13 or later](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)


**GitHub**

🔗 [GitHub CLI v2.30 or later (optional, for cloning repos or managing issues)](https://cli.github.com)

**Kubernetes**

🔗 [Kubectl v1.28 or later (for post-deployment interaction)](https://kubernetes.io/docs/tasks/tools)

**Terraform**

🔗 [Terraform v1.6 or later](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

**jq**

🔗 [jq v1.8 or later](https://jqlang.org/download)