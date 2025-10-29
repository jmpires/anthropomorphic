# Documentation

## Accessing the EC2 Instance
1. Access the instance in a new terminal window and execute:
ssh -i <filename>.pem ubuntu@<ip-address>
ssh -i <filename>.pem ec2-user@<ip-address>


# Destroy an instance and associated resources
aws ec2 terminate-instances --instance-ids <instance id>

The Complete Practical Guide to Helm for Kubernetes: From Basics to Production Best Practices


# -----------------------
# Sequence 4 Control Plane/Worker Node(s)

ssh into ControlPlane
copy/paste the script <k8Bootstrap.sh>
sudo vi k8s-control-plane.sh
sudo chmod +x k8s-control-plane.sh
sudo ./k8s-control-plane.sh 2>&1 | tee install.log

into the worker node (for each of them) run:
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

sudo apt update
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
sudo systemctl status containerd  # should be "active (running)"
ls /var/run/containerd/containerd.sock  # should exist
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-kubernetes.conf
sudo sysctl --system
cat /proc/sys/net/ipv4/ip_forward  # should output "1"


sudo apt-mark hold kubelet kubeadm kubectl


into ControlPlane run the command: kubeadm token create --print-join-command
paste the result it into worker nodes after previous step, e.g.: 
+ sudo kubeadm join 172.31.25.18:6443 --token nx05oi.gpxb2sq5qkxn5k6l --discovery-token-ca-cert-hash sha256:c49062c7de51629a8c72ccc8249b0a08d32366eaf898c7ffa97c983608be4b58

