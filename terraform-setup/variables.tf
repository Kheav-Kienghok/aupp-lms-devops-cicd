variable "aws_region" {
  description = "AWS region for the EC2 instances"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name for the AWS key pair to create"
  type        = string
  default     = "devop-final-key"
}

variable "ami_id" {
  description = "AMI ID to use for EC2 instances (set an AMI allowed by your organization policies)"
  type        = string
  default     = "ami-009d9173b44d0482b"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR format, used for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_user" {
  description = "SSH user for the selected AMI"
  type        = string
  default     = "ubuntu"
}

variable "instance_type" {
  description = "EC2 instance type for both servers"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root volume size in GiB"
  type        = number
  default     = 30
}

variable "provision_with_ansible" {
  description = "Run Ansible after the instances are created"
  type        = bool
  default     = true
}
