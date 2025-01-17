packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

data "amazon-ami" "ubuntu-ami" {
  filters = {
    virtualization-type = "hvm"
    name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
    root-device-type    = "ebs"
  }
  owners      = ["099720109477"]
  most_recent = true
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "golden-ami" {
  ami_name      = "golden-ami-${local.timestamp}"
  instance_type = "t2.medium"
  region        = "us-east-1"
  source_ami    = data.amazon-ami.ubuntu-ami.id
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
  sources = ["source.amazon-ebs.golden-ami"]
  provisioner "shell" {
    scripts = ["install_awscli.sh", "install_cloudwatch.sh", "install_ssm.sh"]
  }
}