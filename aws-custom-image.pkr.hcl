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

source "amazon-ebs" "aws_custom_image" {
  access_key                  = "AKIAT4GVRRJX22GHSS7A"
  secret_key                  = "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"
  region                      = var.aws_region
  source_ami                  = "ami-04b4f1a9cf54c11d0"
  instance_type               = "t2.micro"
  ssh_username                = "ubuntu"
  ami_name                    = "custom-ubuntu-24.04-ami-{{timestamp}}"
  vpc_id                      = "vpc-067e649a2e24be3b0"
  subnet_id                   = "subnet-067f64dce030489fb"
  ssh_keypair_name            = "ec2_keypair"
  ssh_private_key_file        = "./ec2_keypair.pem"
  security_group_ids          = ["sg-0b4ff83196afd93f1"]
  associate_public_ip_address = true

  # Ensuring the image is private
  ami_users = []

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
    source      = "./webapp.zip"        # Your local webapp.zip
    destination = "/home/ubuntu/webapp.zip"  # Ensure correct destination
  }

  # Provision MySQL, Node.js, and setup
  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]

    inline = [
      # Update the package list
      "sudo apt-get update",

      # Install required packages
      "sudo apt-get install -y nodejs",
      "sudo apt-get install mysql-server -y",
      "sudo apt-get install unzip -y",
      "sudo apt-get install npm -y",
      
      #change authentication method from auth_socket to native password
      "sudo mysql -u root -p'AuzJ7268*' -e \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'AuzJ7268*';\"",
      #Create the database in the RDBMS.

      "mysql -u root -p'AuzJ7268*' -e \"CREATE DATABASE cloud_computing;\"",

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
      "echo '[Unit]\\nDescription=CSYE 6225 App\\nConditionPathExists=/opt/application.properties\\nAfter=network.target\\n\\n[Service]\\nType=simple\\nUser=csye6225\\nGroup=csye6225\\nWorkingDirectory=/opt/csye6225/webapp\\nExecStart=/usr/bin/node /opt/csye6225/webapp/app.js\\nRestart=always\\nRestartSec=3\\nStandardOutput=syslog\\nStandardError=syslog\\nSyslogIdentifier=csye6225\\n\\n[Install]\\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/csye6225.service > /dev/null",

      # Reload systemd to recognize the new service
      "sudo systemctl daemon-reload",

      # Enable the service to start on boot
      "sudo systemctl enable csye6225.service"
    ]
  }

}