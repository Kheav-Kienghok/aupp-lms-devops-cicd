output "ec2_public_ip" {
  value = module.compute.public_ip
}

output "ec2_instance_id" {
  value = module.compute.instance_id
}

output "ansible_inventory_path" {
  value = var.provision_with_ansible ? local_file.ansible_inventory[0].filename : null
}