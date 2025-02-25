variable "project_id" {
  default = "dev-project-452005"
}

variable "image_name" {
  default = "custom-ubuntu-24-04"
}

variable "machine_type" {
  default = "e2-micro"
}

variable "zone" {
  default = "us-central1-a"
}

source "googlecompute" "ubuntu" {
  project_id           = var.project_id
  source_image_family  = "ubuntu-2404-lts"
  source_image_project = "ubuntu-os-cloud"
  machine_type         = var.machine_type
  zone                 = var.zone
  image_name           = var.image_name
  image_family         = "custom-ubuntu"
  image_description    = "Custom Ubuntu 24.04 LTS Image"
  disk_size            = "10"
}

build {
  sources = ["source.googlecompute.ubuntu"]

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

      #change authentication method from auth_socket to native password
      "sudo mysql -u root -p'${var.db_root_password}' -e \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${var.db_root_password}';\"",
      #Create the database in the RDBMS.

      "mysql -u root -p'${var.db_root_password}' -e \"CREATE DATABASE ${var.db_name};\"",

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