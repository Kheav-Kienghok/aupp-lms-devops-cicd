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
