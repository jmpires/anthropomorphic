#!/bin/bash
# Script name: k8WorkerNode.sh
# Description: This script creates a worker node(s) in an AWS instance.
# OS supported: MacOS, Linux
# Author: Jorge Manuel Pires
# Contributors: Jorge Manuel Pires
# Initial Version.Last Updated(updates)	:v20251008.v20251027(5)

# For debugging purposes
# set -x

# Exit on any error
set -e

# --- Ensure keyrings directory exists
sudo mkdir -p /etc/apt/keyrings

# --- Disable swap (required by kubectl)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# --- Load required kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# --- Configure sysctl for CNI compatibility
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# --- Install Kubernetes packages (v1.29)
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# --- Install and configure containerd
sudo apt update
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# --- Verify containerd is running
sudo systemctl status containerd --no-pager -l
ls /var/run/containerd/containerd.sock  # should exist

# --- Hold package versions
sudo apt-mark hold kubelet kubeadm kubectl

echo ""
echo "Worker Node is ready!"
echo "Proceed now to create additional Worker Node(s) or join the created ones ..."