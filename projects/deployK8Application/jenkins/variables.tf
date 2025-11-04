# variables.tf

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "availability_zone" {}
variable "env_prefix" {}
variable "instance_type" {}

# IP allowed to access SSH and Jenkins UI (e.g., your workstation's public IP)
variable "allowed_ip_cidr" {
  description = "Your public IP in CIDR notation (e.g., 203.0.113.5/32)"
  type        = string
  default     = "0.0.0.0/0" # ⚠️ Only for demo or development; override in production!
}