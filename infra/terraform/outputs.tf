output "ec2_public_ip" {
  value = module.compute.ec2_public_ip
}

output "ansible_inventory_path" {
  value = var.provision_with_ansible ? local_file.ansible_inventory[0].filename : null
}