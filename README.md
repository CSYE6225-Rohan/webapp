# webapp

Prerequisites for building and deploying your application locally.
1. Node 23.6.1
2. MySQL 9.2.0
3. API Testing tool like Postman
4. MySQL Workbench (optional)

Build and Deploy instructions for the web application.
1. Start MySQL server
2. Execute command "node server.js" to start web server
3. Open API testing tool and hit API "http://localhost:8080/healthz"
4. Check if entry for hit is added in mysql db

Create .env and ubuntu.env from their templates and fill values

Order to run
1. In zsh: settings_ubuntu.sh - this will initialize ubuntu
2. In zsh: setting_files.sh - this will send necessary files to ubuntu
3. In bash: /opt/ubuntu.sh - this will set the ubuntu up for running server

To run server:
npm start

To test:
npm test

Continous Integration:
On creating a pull request to main branch, npm test will happen as it has been added in github workflows. Credentials can be set in github secrets in repo secrets

Creating packer for creation of custom ubuntu ami on default vpc and csye6225.service systemd service which reinitializes the web app if it shuts

The packer can be run using: 
packer build \
  -var "aws_region=<AWS_REGION>" \
  -var "db_host=<DB_HOST>" \
  -var "db_user=<DB_USER>" \
  -var "db_password=<DB_PASSWORD>" \
  -var "db_port=<DB_PORT>" \
  <your-packer-file>.pkr.hcl     

Ubuntu 2404 Custom images will be created on AWS and GCP

test