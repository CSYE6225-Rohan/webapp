# Define required plugins
variable "aws_region" {
  default = "us-east-1"
}

variable "aws_db_root_password" {
  type    = string
  default = "your-root-password"
}

variable "aws_db_name" {
  type    = string
  default = "your-database-name"
}

variable "aws_source_ami" {
  type    = string
  default = "ami-04b4f1a9cf54c11d0"
}

variable "aws_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "aws_ami_name" {
  type    = string
  default = "custom-ubuntu-24.04-ami-{{timestamp}}"
}

variable "aws_ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "aws_shared_users" {
  type    = list(string)
  default = ["273354624515"]
}

packer {
  required_plugins {
    amazon-ebs = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

source "amazon-ebs" "aws_custom_image" {
  region        = var.aws_region
  source_ami    = var.aws_source_ami
  instance_type = var.aws_instance_type
  ssh_username  = var.aws_ssh_username
  ami_name      = var.aws_ami_name
  ami_users     = var.aws_shared_users
  associate_public_ip_address = true

  tags = {
    Name = "Packer AMI"
  }
}

build {
  sources = ["source.amazon-ebs.aws_custom_image"]

  # Copy application artifacts to the instance
  provisioner "file" {
    source      = "./webapp.zip"
    destination = "/home/ubuntu/webapp.zip"
  }

  # Provision MySQL, Node.js, CloudWatch Agent, and setup
  provisioner "shell" {
    inline = [
      # Update the package list
      "DEBIAN_FRONTEND=noninteractive",
      "sudo apt-get update",

      # Install required packages
      "sudo apt-get install -y nodejs unzip npm",


      # Start CloudWatch Agent on boot
      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s",
      "sudo systemctl enable amazon-cloudwatch-agent",

      # Application setup
      "sudo mkdir /opt/csye6225/",
      "sudo unzip /home/ubuntu/webapp.zip -d /opt/csye6225/webapp",
      "sudo groupadd csye6225",
      "sudo useradd -r -s /usr/sbin/nologin -g csye6225 csye6225",
      "sudo chown -R csye6225:csye6225 /opt/csye6225/",
      "cd /opt/csye6225/webapp",
      "sudo npm install",

      # Create a systemd service file for the web app
      "echo '[Unit]\\nDescription=CSYE 6225 App\\nAfter=network.target\\n\\n[Service]\\nType=simple\\nUser=csye6225\\nGroup=csye6225\\nWorkingDirectory=/opt/csye6225/webapp\\nExecStart=/usr/bin/node /opt/csye6225/webapp/server.js\\nRestart=always\\nRestartSec=3\\nStandardOutput=append:/var/log/app.log\\nStandardError=append:/var/log/app.log\\nSyslogIdentifier=csye6225\\n\\n[Install]\\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/csye6225.service > /dev/null",

      # Reload systemd to recognize the new service
      "sudo systemctl daemon-reload",
      "sudo systemctl enable csye6225.service"
    ]
  }
}
