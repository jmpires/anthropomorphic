# 📘 **AWS User Defined K8 Cluster**

### 📖 Article Link
Read the full article on Medium: [101 Setting Up a User Defined Kubernetes Cluster on AWS using Ubuntu Server and Terraform](https://medium.com/@jorgemanuelpires/101-setting-up-a-user-defined-kubernetes-cluster-on-aws-using-ubuntu-server-and-terraform-217b14b80239)


### 📋 Code Structure


## **Terraform files**

```
main.tf - Declares providers and defines the core infrastructure resources.

defaults.auto.tfvars - Automatically supplies default values for variables.

variables.tf - Specifies input variables to parameterize the configuration.

output.tf - Exposes key details of the deployed infrastructure after apply.
```

## **Bash files**

```
deployNodes.sh – Deploys a Kubernetes node (control plane or worker) on an AWS EC2 instance by remotely executing a specified setup script.

k8ControlPlane.sh - Initializes and configures the control plane on an AWS EC2 instance - designed to be executed remotely via SSH.
k8WorkerNodes.sh - Initializes and configures the worker node(s) on an AWS EC2 instance - designed to be executed remotely via SSH.

joinWorkers.sh – Automates joining worker node(s) to the Kubernetes control plane across AWS EC2 instances.

showClusterInfo.sh – Displays cluster information derived from Terraform output.
```

