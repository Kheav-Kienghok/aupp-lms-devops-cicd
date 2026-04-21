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
