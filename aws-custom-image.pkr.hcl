# Define required plugins
packer {
  required_plugins {
    amazon-ebs = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

# Define AWS region as a variable
variable "aws_region" {
  default = "us-east-1"
}

# EC2 Instance Build Configuration
source "amazon-ebs" "aws_custom_image" {
  region         = var.aws_region
  source_ami     = "ami-0f37c4a1ba152af46"  # Replace with the latest Ubuntu AMI ID
  instance_type  = "m6g.medium"
  ssh_username   = "ubuntu"
  ami_name       = "custom-ubuntu-24.04-ami-{{timestamp}}"
  vpc_id         = "vpc-067e649a2e24be3b0"
  subnet_id      = "subnet-067f64dce030489fb"  # Replace with your subnet ID
  ssh_keypair_name = "ec2_keypair"  # Corrected key pair argument
  ssh_private_key_file = "ec2_keypair.pem"
  security_group_ids = ["sg-0b4ff83196afd93f1"]  # Corrected security group argument
  associate_public_ip_address = true

  # Ensuring the image is private
  ami_users = []  # Empty means only your AWS account can access it

  # Tags to apply to the created AMI
  tags = {
    Name = "Packer AMI"
  }
}

# Build Configuration with Provisioners
build {
  sources = ["source.amazon-ebs.aws_custom_image"]

  # Provision MySQL and Node.js
  provisioner "shell" {
    inline = [
      "sudo apt update",
      "sudo apt install -y mysql-server nodejs npm",
      "sudo systemctl enable mysql"
    ]
  }
}