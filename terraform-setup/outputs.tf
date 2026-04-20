output "jenkins_public_ip" {
  value = aws_instance.this["jenkins"].public_ip
}

output "sonarqube_public_ip" {
  value = aws_instance.this["sonarqube"].public_ip
}

output "jenkins_instance_id" {
  value = aws_instance.this["jenkins"].id
}

output "sonarqube_instance_id" {
  value = aws_instance.this["sonarqube"].id
}

output "ansible_inventory_path" {
  value = var.provision_with_ansible ? local_file.ansible_inventory[0].filename : null
}

output "key_pair_name" {
  value = aws_key_pair.this.key_name
}

output "private_key_path" {
  value = local_sensitive_file.private_key_pem.filename
}