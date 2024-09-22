packer {
  required_plugins {
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "aws_access_key" {
  sensitive = true
  type      = string
  default   = "fake"
}

variable "aws_secret_key" {
  sensitive = true
  type      = string
  default   = "fake"
}

variable "ecr_login_url" {
  sensitive = true
  type      = string
  default   = "fake"
}

variable "ecr_registry" {
  sensitive = true
  type      = string
  default   = "fake"
}

variable "aws_region" {
  type      = string
  default   = "us-east-1"
}

variable "aws_account_id" {
  sensitive = true
  type      = string
  default   = "fake"
}

data "amazon-ami" "middleware-ami" {
  filters = {
    virtualization-type = "hvm"
    name                = "middleware-ami-*"
    root-device-type    = "ebs"
  }
  owners      = [var.aws_account_id]
  most_recent = true
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "webapp-ami" {
  ami_name      = "webapp-ami-${local.timestamp}"
  instance_type = "t2.medium"
  region        = "us-east-1"
  source_ami    = data.amazon-ami.middleware-ami.id
  ami_regions	  = ["us-east-2"]
  ami_users 	  = ["837598956765"]
  ssh_username  = "ubuntu"
  run_tags = {
    Name = "packer-vm"
  }
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }
  tags = {
    project = "packer"
  }
}

build {
  sources = ["source.amazon-ebs.webapp-ami"]
  provisioner "shell" {
    environment_vars = [
      "AWS_ACCESS_KEY_ID=${var.aws_access_key}",
      "AWS_SECRET_ACCESS_KEY=${var.aws_secret_key}",
    ]
    inline = [
      "docker login -u AWS -p $(aws ecr get-login-password --region ${var.aws_region}) ${var.ecr_login_url}",
      "docker run -d --name webapp -p 80:80  --restart=always ${var.ecr_registry}",
    ]
  }
}