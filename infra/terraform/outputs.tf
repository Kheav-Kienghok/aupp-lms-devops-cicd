# ─────────────────────────────────────────────
# Instance
# ─────────────────────────────────────────────
output "instance_id" {
  description = "EC2 instance ID"
  value       = module.compute.instance_id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.compute.ec2_public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.compute.ec2_public_dns
}

# ─────────────────────────────────────────────
# Key pair
# ─────────────────────────────────────────────
output "key_pair_name" {
  description = "Name of the AWS key pair in use (created or existing)"
  value       = local.resolved_key_name
}

output "key_pair_source" {
  description = "Whether the key pair was 'created' or 'existing'"
  value       = local.create_key ? "created" : "existing"
}

output "private_key_path" {
  description = "Path to the private key on the Jenkins host"
  value       = var.ssh_private_key_path
}

# ─────────────────────────────────────────────
# Ansible
# ─────────────────────────────────────────────
output "ansible_inventory_path" {
  description = "Path to the generated Ansible inventory file"
  value       = local_file.ansible_inventory.filename
}

# ─────────────────────────────────────────────
# Docker image
# ─────────────────────────────────────────────
output "docker_image" {
  description = "Full Docker image reference used by the deploy playbook"
  value       = local.image_full
}

# ─────────────────────────────────────────────
# SSH quick-connect
# ─────────────────────────────────────────────
output "ssh_command" {
  description = "Ready-to-use SSH command for the instance"
  value       = "ssh -i ${var.ssh_private_key_path} ${var.ssh_user}@${module.compute.ec2_public_ip}"
}