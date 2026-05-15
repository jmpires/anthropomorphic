# variables.tf

variable "region" {}
variable "cluster_name" {}
variable "cluster_version" {}

variable "vpc_name" {}
variable "vpc_cidr" {}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "node_desired" {}
variable "node_min" {}
variable "node_max" {}

variable "instance_types" {
  type = list(string)
}