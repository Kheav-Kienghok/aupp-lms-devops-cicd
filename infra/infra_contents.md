# Infra Folder Contents

This document includes all files inside the `infra` folder and subfolders, excluding `.terraform.lock.hcl`.

The `deploy.yml` playbook is located at `infra/ansible/playbooks/deploy.yml`.

## Files Included

- `ansible/playbooks/deploy.yml`
- `ansible/playbooks/server.yml`
- `terraform/main.tf`
- `terraform/outputs.tf`
- `terraform/variables.tf`
- `terraform/modules/compute/main.tf`
- `terraform/modules/compute/outputs.tf`
- `terraform/modules/compute/variables.tf`
- `terraform/templates/inventory.ini.tftpl`

---

## `ansible/playbooks/deploy.yml`

```yaml
- name: Deploy application using Docker Compose V2
  hosts: servers
  become: true
  gather_facts: false

  vars:
    deploy_dir: /home/ubuntu/deploy

  tasks:
    - name: Ensure deployment directory exists
      ansible.builtin.file:
        path: "{{ deploy_dir }}"
        state: directory
        owner: ubuntu
        group: ubuntu
        mode: "0755"

    - name: Copy deploy folder to target host
      ansible.builtin.copy:
        src: "{{ playbook_dir }}/../../../deploy/"
        dest: "{{ deploy_dir }}/"
        owner: ubuntu
        group: ubuntu
        mode: preserve

    - name: Pull Docker image (specific tag)
      ansible.builtin.command: "docker pull {{ image_full }}"
      changed_when: true

    - name: Tag image as latest
      ansible.builtin.command: "docker tag {{ image_full }} {{ image_repo }}:latest"
      changed_when: true

    - name: Restart services using Docker Compose V2
      community.docker.docker_compose_v2:
        project_src: "{{ deploy_dir }}"
        state: present
        recreate: always
        remove_orphans: true

    - name: Show running containers
      ansible.builtin.command: docker ps
      changed_when: false
```

---

## `ansible/playbooks/server.yml`

```yaml
- name: Configure server with Docker and Docker Compose
  hosts: servers
  become: true
  gather_facts: true

  pre_tasks:
    - name: Wait for cloud-init to finish when available
      ansible.builtin.shell: |
        if command -v cloud-init >/dev/null 2>&1; then
          cloud-init status --wait
        fi
      changed_when: false

    - name: Update apt packages
      ansible.builtin.apt:
        update_cache: true
        upgrade: dist
      when: ansible_facts.os_family == "Debian"

    - name: Update dnf packages
      ansible.builtin.dnf:
        name: "*"
        state: latest
        update_only: true
      when: ansible_facts.os_family == "RedHat"

  tasks:
    - name: Install curl on Debian
      ansible.builtin.apt:
        name: curl
        state: present
      when: ansible_facts.os_family == "Debian"

    - name: Install curl on RedHat
      ansible.builtin.dnf:
        name: curl
        state: present
      when: ansible_facts.os_family == "RedHat"

    - name: Install Docker using official convenience script
      ansible.builtin.shell: |
        curl -fsSL https://get.docker.com | sh
      args:
        creates: /usr/bin/docker

    - name: Ensure docker service is enabled and running
      ansible.builtin.service:
        name: docker
        state: started
        enabled: true

    - name: Install docker compose plugin on Debian
      ansible.builtin.apt:
        name: docker-compose-plugin
        state: present
      when: ansible_facts.os_family == "Debian"

    - name: Install docker compose plugin on RedHat
      ansible.builtin.dnf:
        name: docker-compose-plugin
        state: present
      when: ansible_facts.os_family == "RedHat"
      ignore_errors: true

    - name: Verify docker compose is available
      ansible.builtin.command: docker compose version
      register: docker_compose_check
      changed_when: false
      failed_when: docker_compose_check.rc != 0

    - name: Ensure deploy directory exists on Ubuntu
      ansible.builtin.file:
        path: /home/ubuntu/deploy
        state: directory
        owner: ubuntu
        group: ubuntu
        mode: "0755"

    - name: Copy deploy folder to Ubuntu
      ansible.builtin.copy:
        src: "{{ playbook_dir }}/../../../deploy/"
        dest: /home/ubuntu/deploy/
        owner: ubuntu
        group: ubuntu
        mode: preserve
```

---

## `terraform/main.tf`

```hcl
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
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key ${abspath(var.ssh_private_key_path)} -i ${local_file.ansible_inventory[0].filename} ${abspath(\"${path.module}/../ansible/playbooks/server.yml\")}"
  }
}
```

---

## `terraform/outputs.tf`

```hcl
output "ec2_public_ip" {
  value = module.compute.ec2_public_ip
}

output "ansible_inventory_path" {
  value = var.provision_with_ansible ? local_file.ansible_inventory[0].filename : null
}
```

---

## `terraform/variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix used for naming AWS resources"
  type        = string
  default     = "aupp-lms"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "Amazon Linux 2023 or Ubuntu AMI ID"
  type        = string
  default     = "ami-009d9173b44d0482b" # Update with the latest AMI ID for your region
}

variable "key_name" {
  description = "Existing AWS key pair"
  type        = string
  default     = "devop-final-key"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR format, example 1.2.3.4/32"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_private_key_path" {
  description = "Local path to the SSH private key matching key_name"
  type        = string
  default     = "../keys/devop-final-key.pem"
}

variable "ssh_user" {
  description = "SSH user for the EC2 instance (ec2-user for AL2023, ubuntu for Ubuntu)"
  type        = string
  default     = "ubuntu"
}

variable "provision_with_ansible" {
  description = "Run Ansible server provisioning after instance creation"
  type        = bool
  default     = true
}
```

---

## `terraform/modules/compute/main.tf`

```hcl
resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-sg"
  description = "Allow SSH, app, Prometheus, and Grafana"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "Application"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg"
  }
}

data "aws_key_pair" "selected" {
  key_name = var.key_name
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.selected.key_name
  vpc_security_group_ids = [aws_security_group.this.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    hostname = "${var.name_prefix}-ec2"
  })

  tags = {
    Name = "${var.name_prefix}-ec2"
  }
}
```

---

## `terraform/modules/compute/outputs.tf`

```hcl
output "instance_id" {
  value = aws_instance.this.id
}

output "ec2_public_ip" {
  value = aws_instance.this.public_ip
}

output "security_group_id" {
  value = aws_security_group.this.id
}
```

---

## `terraform/modules/compute/variables.tf`

```hcl
variable "name_prefix" {
  description = "Prefix used for naming AWS resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for EC2 instances (set an AMI allowed by your organization policies)"
  type        = string
}

variable "my_ip_cidr" {
  description = "CIDR used to restrict SSH/monitoring access"
  type        = string
}
```

---

## `terraform/templates/inventory.ini.tftpl`

```ini
[servers]
app ansible_host=${host} ansible_user=${ssh_user} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

---

## Notes

- The file `.terraform.lock.hcl` in `infra/terraform` was explicitly ignored, as requested.
