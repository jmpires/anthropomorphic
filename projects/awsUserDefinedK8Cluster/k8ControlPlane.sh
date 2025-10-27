#!/bin/bash
# Script name: k8WorkerNode.sh
# Description: This script creates the Control Plane in an AWS instance.
# OS supported: MacOS, Linux
# Author: Jorge Manuel Pires
# Contributors: Jorge Manuel Pires
# Initial Version.Last Updated(updates)	:v20251008.v20251027(5)

# For debugging purposes
# set -x

# Exit on any error
set -e

# Wait for cloud-init to finish
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
  sleep 1
done

export DEBIAN_FRONTEND=noninteractive

# --- Disable swap
echo "🔧 Disabling swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# --- Kernel modules
echo "🔧 Loading kernel modules..."
modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# --- Step 3: Sysctl settings
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system >/dev/null 2>&1

# --- Step 4: Install and configure containerd
echo "🔧 Installing containerd..."
apt update
apt install -y containerd

mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable --now containerd

# --- Step 5: Install Kubernetes (v1.29)
echo "🔧 Installing Kubernetes..."

# ✅ FIXED: NO SPACES in URLs
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet

# --- Step 6: Initialize cluster
echo "🔧 Initializing Kubernetes cluster..."
kubeadm init --pod-network-cidr=192.168.0.0/16

# --- Step 7: Configure kubectl for ROOT
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# --- Step 8: Configure kubectl for UBUNTU user
echo "🔧 Configuring kubectl for 'ubuntu' user..."
if id "ubuntu" &>/dev/null; then
  sudo -u ubuntu mkdir -p /home/ubuntu/.kube
  cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  chown -R ubuntu:ubuntu /home/ubuntu/.kube
  echo "✅ You can now run 'kubectl' as the 'ubuntu' user!"
else
  echo "⚠️  'ubuntu' user not found. Skipping user config."
fi

# --- Step 9: Remove control-plane taint
kubectl taint nodes --all node-role.kubernetes.io/control-plane- 2>/dev/null || true

# --- Step 10: Install Calico with auto-detected interface
echo "🔧 Installing Calico..."

PRIMARY_IFACE=$(ip -o addr show up primary scope global 2>/dev/null | awk '{print $2; exit}' | sed 's/://')
if [ -z "$PRIMARY_IFACE" ]; then
  PRIMARY_IFACE=$(ip -o link show | awk -F': ' '$2 !~ /^lo/ && /state UP/ {print $2; exit}')
fi
if [ -z "$PRIMARY_IFACE" ]; then
  PRIMARY_IFACE="ens5"
fi

echo "Using network interface: $PRIMARY_IFACE"

# ✅ Use pinned Calico version that supports your original sed
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# ✅ Your original, working sed command (now safe with v3.26.1)
sed -i '/# Auto-detect the BGP IP address\./,/value: "autodetect"/{
  /value: "autodetect"/a\
            - name: IP_AUTODETECTION_METHOD\n              value: "interface='"$PRIMARY_IFACE"'"
}' calico.yaml

# Enable MTU 9001 for AWS
sed -i 's/# - name: FELIX_MTU/- name: FELIX_MTU/' calico.yaml
sed -i 's/#   value: "1500"/  value: "9001"/' calico.yaml

kubectl apply -f calico.yaml

# Alias setup for kubectes completion
echo 'alias k=kubectl' >> ~/.bashrc
source ~/.bashrc

echo ""
echo "Control Plane is ready!"
echo "Log in as 'ubuntu' and run: kubectl get nodes."
echo "All system pods should be Running in 1-2 minutes ..."
echo "Proceed now to create the Worker Node(s) ..."