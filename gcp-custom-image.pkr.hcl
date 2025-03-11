variable "gcp_project_id" {
  default = "dev-project-452005"
}

variable "image_name" {
  default = "custom-ubuntu-24-04-{{timestamp}}"
}

variable "image_family" {
  default = "custom-ubuntu"
}

variable "image_description" {
  default = "Custom Ubuntu 24.04 LTS Image"
}

variable "source_image_family" {
  default = "ubuntu-2404-lts"
}

variable "source_image" {
  default = "ubuntu-2404-noble-amd64-v20250214"
}

variable "machine_type" {
  default = "e2-micro"
}

variable "zone" {
  default = "us-central1-b"
}

variable "disk_size" {
  default = 10
}

variable "ssh_username" {
  default = "packer"
}

variable "db_name" {
  type    = string
  default = "your-database-name"
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "db_host" {
  type    = string
  default = "your-database-host"
}

variable "db_user" {
  type    = string
  default = "your-database-user"
}

variable "db_password" {
  type    = string
  default = "your-database-password"
}

variable "db_root_password" {
  type    = string
  default = "your-root-password"
}

source "googlecompute" "ubuntu" {
  project_id          = var.gcp_project_id
  source_image_family = var.source_image_family
  source_image        = var.source_image
  machine_type        = var.machine_type
  zone                = var.zone
  image_name          = var.image_name
  image_family        = var.image_family
  image_description   = var.image_description
  disk_size           = var.disk_size
  ssh_username        = var.ssh_username
}

build {
  sources = ["source.googlecompute.ubuntu"]
  # Copy application artifacts to the instance
  provisioner "file" {
    source      = "./webapp.zip"
    destination = "/tmp/webapp.zip"
  }


  provisioner "shell" {
    inline = [
      # Update the package list
      "DEBIAN_FRONTEND=noninteractive",
      "sudo apt-get update",

      # Install required packages
      "sudo apt-get install -y nodejs",
      "sudo apt-get install mysql-server -y",
      "sudo apt-get install unzip -y",
      "sudo apt-get install npm -y",

      # Change authentication method from auth_socket to native password
      "sudo mysql -u root -p'${var.db_root_password}' -e \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${var.db_root_password}';\"",

      # Create the database in the RDBMS
      "mysql -u root -p'${var.db_root_password}' -e \"CREATE DATABASE ${var.db_name};\"",

      # Create directory for app files
      "sudo mkdir -p /opt/csye6225/",

      # Unzip the application files (Ensure 'webapp.zip' is available on the build machine)
      "sudo unzip /tmp/webapp.zip -d /opt/csye6225/webapp",

      # Create the user and group
      "sudo groupadd csye6225",
      "sudo useradd -r -s /usr/sbin/nologin -g csye6225 csye6225",

      # Change ownership of the application files
      "sudo chown -R csye6225:csye6225 /opt/csye6225/",

      # Navigate into the webapp directory
      "cd /opt/csye6225/webapp",

      # Install application dependencies
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