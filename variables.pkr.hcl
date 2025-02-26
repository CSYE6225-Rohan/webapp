variable "gcp_project_id" {
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

variable "db_name" {
  type    = string
  default = "mydatabase"
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "db_host" {
  type    = string
  default = "localhost"
}

variable "db_user" {
  type    = string
  default = "rohan"
}

variable "db_password" {
  type    = string
  default = "default"
}

variable "db_root_password" {
  type    = string
  default = "default"
}

variable "aws_region" {
  default = "us-east-1"
}