output "ec2_public_ip" {
  value = module.compute.ec2_public_ip
}

output "ec2_instance_id" {
  value = module.compute.instance_id
}

output "ansible_inventory_path" {
  value = local_file.ansible_inventory.filename
}

output "private_key_path" {
  value = var.ssh_private_key_path
}
