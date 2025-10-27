# outputs.tf
output "private_key_path" {
  description = "Path to private key file"
  value       = local_file.KeyPair_pem.filename
  sensitive   = true
}

output "instance_summary" {
  description = "Instance details (non-sensitive)"
  value = {
    region = data.aws_region.current
    instances = {
      for k, v in aws_instance.k8s_node : k => {
        name        = v.tags.Name
        role        = v.tags.Role
        public_ip   = v.public_ip
        id          = v.id
        ssh_command = "ssh -i ${var.key_pair_filename} ubuntu@${v.public_ip}"
      }
    }
    instance_ids = values(aws_instance.k8s_node)[*].id
    public_ips   = values(aws_instance.k8s_node)[*].public_ip
  }
}