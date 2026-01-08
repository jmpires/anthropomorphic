# --- SSH Key Pair ---
variable "algorithm_id" {
  type = string
  # default     = "RSA"
  description = "Algorithm used for the SSH key pair (e.g., RSA, ECDSA)."
}

variable "rsa_bits_id" {
  type = number
  # default     = 2048
  description = "The bit length of the RSA key (e.g., 2048, 4096)."
}

# --- AWS Configuration ---
variable "region_id" {
  type = string
  # default     = "us-east-1"
  description = "The AWS region where the resources will be created."
}

variable "aws_profile" {
  type = string
  # default = "jorgepires"   # certification account
  # default     = "jmpires" # permanent account 
  description = "The AWS profile to be used to deploy."
}

variable "availability_zones" {
  description = "List of availability zones to create subnets in for high availability"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"] # 3 AZs for HA without over-provisioning
}

# --- Instance & Cluster Configuration ---
# Simple way to define cluster size
variable "total_instances" {
  description = "Total number of Kubernetes nodes. If 1 → single control-plane. If >1 → 1 control-plane + (N-1) workers."
  type        = number
  default     = 1
}

# Optional overrides (only needed if you want non-defaults)
variable "default_ami" {
  description = "Default AMI for all nodes (used when not overridden)"
  type        = string
  default     = "ami-0bbdd8c17ed981ef9" # Ubuntu 22.04 LTS — you can change this
}

variable "control_plane_instance_type" {
  description = "Instance type for control-plane node(s)"
  type        = string
  # default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for worker node(s)"
  type        = string
  # default     = "t3.small"
}

# Advanced: Full manual control (optional — leave unset for auto-mode)
variable "k8s_nodes" {
  description = "Advanced: Explicitly define node groups. If not set, auto-generated from total_instances."
  type = map(object({
    instance_type = string
    ami           = string
    count         = number
    role          = string # e.g., "control-plane" or "worker"
  }))
  default = null # ← important: allows detection of "not set"
}

# --- Key Pair & Naming ---
# Key Pair created for this specific instance
variable "aws_key_pair_id" {
  type = string
  # default     = "smallEKSClusterKeyPair"
  description = "The name of the AWS key pair to be created and used."
}

variable "key_pair_filename" {
  type = string
  # default     = "smallEKS-KeyPair.pem"  # optional fallback
  description = "Filename for the private key PEM file"
}

variable "aws_security_group_id" {
  type = string
  # default     = "smallEKSClusterSecurityGroup"
  description = "The name of the security group that will allow SSH access."
}

variable "instance_name_id" {
  type = string
  # default     = "smallEKSClusterInstance"
  description = "The name tag for the EC2 instance."
}

# --- Kubernetes Specific Config --- ###################################
variable "nodeport_range_start" {
  description = "Start of NodePort range"
  type        = number
  default     = 30000
}

variable "nodeport_range_end" {
  description = "End of NodePort range"
  type        = number
  default     = 32767
}