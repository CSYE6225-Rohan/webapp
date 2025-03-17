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

variable "aws_shared_users"{
  type   = list(string)
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

  # Tags to apply to the created AMI
  tags = {
    Name = "Packer AMI"
  }
}

# Build Configuration with Provisioners
build {
  sources = ["source.amazon-ebs.aws_custom_image"]

  # Copy application artifacts to the instance
  provisioner "file" {
    source      = "./webapp.zip"
    destination = "/home/ubuntu/webapp.zip"
  }

  # Provision MySQL, Node.js, and setup
  provisioner "shell" {

    inline = [
      # Update the package list
      "DEBIAN_FRONTEND=noninteractive",
      "sudo apt-get update",

      # Install required packages
      "sudo apt-get install -y nodejs",
      # "sudo apt-get install mysql-server -y",
      "sudo apt-get install unzip -y",
      "sudo apt-get install npm -y",

      #change authentication method from auth_socket to native password
      # "sudo mysql -u root -p'${var.aws_db_root_password}' -e \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${var.aws_db_root_password}';\"",
      #Create the database in the RDBMS.

      # "mysql -u root -p'${var.aws_db_root_password}' -e \"CREATE DATABASE ${var.aws_db_name};\"",

      # Making csye6225 repo
      "sudo mkdir /opt/csye6225/",

      # Unzip the application files
      "sudo unzip /home/ubuntu/webapp.zip -d /opt/csye6225/webapp",

      # Create the user and group
      "sudo groupadd csye6225",
      "sudo useradd -r -s /usr/sbin/nologin -g csye6225 csye6225",

      # Change ownership of the application files
      "sudo chown -R csye6225:csye6225 /opt/csye6225/",

      #going into webapp directory
      "cd /opt/csye6225/webapp",

      # Install dependencies
      "sudo npm install",

      # Create a systemd service file
      "echo '[Unit]\\nDescription=CSYE 6225 App\\nAfter=network.target\\n\\n[Service]\\nType=simple\\nUser=csye6225\\nGroup=csye6225\\nWorkingDirectory=/opt/csye6225/webapp\\nExecStart=/usr/bin/node /opt/csye6225/webapp/server.js\\nRestart=always\\nRestartSec=3\\nStandardOutput=syslog\\nStandardError=syslog\\nSyslogIdentifier=csye6225\\n\\n[Install]\\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/csye6225.service > /dev/null",

      # Reload systemd to recognize the new service
      "sudo systemctl daemon-reload",

      # Enable the service to start on boot
      "sudo systemctl enable csye6225.service"
    ]
  }

}