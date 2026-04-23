terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_key_pair" "existing" {
  key_name = var.key_name
}

module "compute" {
  source = "./modules/compute"

  name_prefix   = var.name_prefix
  ami_id        = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  my_ip_cidr    = var.my_ip_cidr
}

resource "local_file" "ansible_inventory" {
  count = var.provision_with_ansible ? 1 : 0

  content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    host             = module.compute.ec2_public_ip
    ssh_user         = var.ssh_user
  })
  filename = "${path.module}/../ansible/inventory.ini"
}

resource "null_resource" "wait_for_cloud_init" {
  count = var.provision_with_ansible ? 1 : 0

  triggers = {
    instance_id = module.compute.instance_id
  }

  connection {
    type        = "ssh"
    host        = module.compute.ec2_public_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || true",
    ]
  }
}

resource "null_resource" "ansible_provision" {
  count = var.provision_with_ansible ? 1 : 0

  depends_on = [
    local_file.ansible_inventory[0],
    null_resource.wait_for_cloud_init[0],
  ]

  triggers = {
    instance_id = module.compute.instance_id
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key ${abspath(var.ssh_private_key_path)} -i ${local_file.ansible_inventory[0].filename} ${abspath("${path.module}/../ansible/playbooks/server.yml")}"
  }
}