# --- Key pair config ---
algorithm_id = "RSA"
rsa_bits_id  = 2048
region_id    = "us-east-1"

# --- Kubernetes cluster size ---
total_instances             = 2
control_plane_instance_type = "t3.small"
worker_instance_type        = "t3.small"

# --- (Optional) Override defaults if needed ---
# default_ami                 = "ami-0bbdd8c17ed981ef9"
# control_plane_instance_type = "t3.medium"
# worker_instance_type        = "t3.small"

# --- Key & network config ---
aws_key_pair_id       = "k8ClusterKeyPair"
key_pair_filename     = "k8ClusterKeyPair.pem"
aws_security_group_id = "k8ClusterSecurityGroup"
instance_name_id      = "k8ClusterInstance"
aws_profile           = "jmpires" # replace with your AWS CLI profile name