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
  default     = "ami-009d9173b44d0482b"
}

variable "key_name" {
  description = "Name for the new AWS key pair (only used when existing_key_pair_name is empty)"
  type        = string
  default     = "devop-final-key-1"
}

variable "existing_key_pair_name" {
  description = "Name of an existing AWS key pair to reuse. Leave empty to auto-generate a new one."
  type        = string
  default     = ""
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR format, e.g. 1.2.3.4/32"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_user" {
  description = "SSH user for the EC2 instance"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Absolute path to the SSH public key on the Jenkins host"
  type        = string
  default     = "/var/lib/jenkins/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Absolute path to the SSH private key on the Jenkins host"
  type        = string
  default     = "/var/lib/jenkins/.ssh/id_rsa"
}

variable "provision_with_ansible" {
  description = "Run Ansible server provisioning after instance creation"
  type        = bool
  default     = true
}

variable "image_name" {
  description = "Docker image name used by the deploy playbook"
  type        = string
  default     = "kienghok/aupp-lms"
}

variable "image_tag" {
  description = "Docker image tag used by the deploy playbook"
  type        = string
  default     = "latest"
}