variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default = "ap-southeast-1"
}

variable "name_prefix" {
  description = "Prefix used for naming AWS resources"
  type        = string
  default     = "aupp-lms"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default = "t2.micro"
}

variable "ami_id" {
  description = "Amazon Linux 2023 or Ubuntu AMI ID"
  type        = string
}

variable "key_name" {
  description = "Existing AWS key pair"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR format, example 1.2.3.4/32"
  type        = string
}

variable "private_key_path" {
  description = "Local path to the SSH private key matching key_name"
  type        = string
  default     = ""
}

variable "ssh_user" {
  description = "SSH user for the EC2 instance (ec2-user for AL2023, ubuntu for Ubuntu)"
  type        = string
  default     = "ec2-user"
}

variable "provision_with_ansible" {
  description = "Run Ansible server provisioning after instance creation"
  type        = bool
  default     = false
}