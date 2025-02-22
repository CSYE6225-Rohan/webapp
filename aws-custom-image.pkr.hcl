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
  access_key                  = "AKIAT4GVRRJX22GHSS7A"
  secret_key                  = "/RcyB3Hj3AyW08sNNFg8Nv7sSBYBBMkZDEtaJGLK"
  region                      = var.aws_region
  source_ami                  = "ami-04b4f1a9cf54c11d0" # Replace with the latest Ubuntu AMI ID
  instance_type               = "t3.micro"
  ssh_username                = "ubuntu"
  ami_name                    = "custom-ubuntu-24.04-ami-{{timestamp}}"
  vpc_id                      = "vpc-067e649a2e24be3b0"
  subnet_id                   = "subnet-067f64dce030489fb" # Replace with your subnet ID
  ssh_keypair_name            = "ec2_keypair"              # Corrected key pair argument
  ssh_private_key_file        = "./ec2_keypair.pem"
  security_group_ids          = ["sg-0b4ff83196afd93f1"] # Corrected security group argument
  associate_public_ip_address = true

  # Ensuring the image is private
  ami_users = [] # Empty means only your AWS account can access it

  # Tags to apply to the created AMI
  tags = {
    Name = "Packer AMI"
  }
}

# Build Configuration with Provisioners
build {
  sources = ["source.amazon-ebs.aws_custom_image"]
  provisioner "file" {
    source      = "./webapp.zip"
    destination = "/home/ubuntu/webapp" # Path on the Ubuntu instance where files will be copied
  }
  # Provision MySQL and Node.js
  provisioner "shell" {
    inline = [
      "sudo apt update",
      "sudo apt install -y mysql-server nodejs npm",
      "sudo systemctl enable mysql"
    ]
  }
}