variable "service_name"  { type = string }
variable "instance_type" { type = string; default = "t2.micro" }
variable "port"          { type = number }
variable "region"        { type = string; default = "us-east-1" }
variable "key_name"      { type = string }

# Docker Hub
variable "docker_username" { type = string; sensitive = true }
variable "docker_password" { type = string; sensitive = true }
variable "image_name"      { type = string }

# Conexiones (IPs de tu instancia "core-infra")
variable "rabbitmq_host" { type = string }
variable "rabbitmq_user" { type = string; default = "guest" }
variable "rabbitmq_pass" { type = string; sensitive = true; default = "guest" }
variable "postgres_url"  { type = string; sensitive = true }
variable "mongo_url"     { type = string; sensitive = true }
